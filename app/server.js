'use strict';

// Minimal notes API for the S3 multi-region DR demo.
//  GET  /api/healthz  -> 200 (Front Door health probe)
//  GET  /api/whoami   -> { region } (proves which region served the request)
//  GET  /api/notes    -> list notes
//  POST /api/notes    -> insert a note; returns 503 when READ_ONLY=true (DR replica)
//  GET  /             -> tiny HTML page showing the serving region + notes

const http = require('http');
const { Pool } = require('pg');

const REGION = process.env.REGION || 'unknown';
const READ_ONLY = process.env.READ_ONLY === 'true';
const PORT = parseInt(process.env.PORT || '8080', 10);

const pool = new Pool({
  host: process.env.PGHOST,
  port: parseInt(process.env.PGPORT || '5432', 10),
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE || 'notes',
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

async function ensureSchema() {
  // Only the primary (read-write) can create the table; the replica inherits it.
  if (READ_ONLY) return;
  await pool.query(
    'CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, title TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT now())'
  );
}

function json(res, code, body) {
  res.writeHead(code, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/api/healthz') {
      return json(res, 200, { status: 'ok', region: REGION });
    }
    if (req.method === 'GET' && req.url === '/api/whoami') {
      return json(res, 200, { region: REGION, readOnly: READ_ONLY });
    }
    if (req.method === 'GET' && req.url === '/api/notes') {
      const r = await pool.query('SELECT id, title, created_at FROM notes ORDER BY id DESC LIMIT 100');
      return json(res, 200, { region: REGION, notes: r.rows });
    }
    if (req.method === 'POST' && req.url === '/api/notes') {
      if (READ_ONLY) {
        return json(res, 503, { error: 'read-only replica; writes disabled until promotion', region: REGION });
      }
      let raw = '';
      req.on('data', (c) => (raw += c));
      req.on('end', async () => {
        try {
          const body = raw ? JSON.parse(raw) : {};
          const title = (body.title || '').toString().slice(0, 500);
          if (!title) return json(res, 400, { error: 'title required' });
          const r = await pool.query('INSERT INTO notes(title) VALUES($1) RETURNING id, title, created_at', [title]);
          return json(res, 201, { region: REGION, note: r.rows[0] });
        } catch (e) {
          return json(res, 500, { error: String(e.message || e) });
        }
      });
      return;
    }
    if (req.method === 'GET' && req.url === '/') {
      res.writeHead(200, { 'content-type': 'text/html' });
      return res.end(
        `<!doctype html><html><head><meta charset="utf-8"><title>Notes · ${REGION}</title>` +
          `<style>body{font-family:system-ui;margin:3rem;max-width:40rem}code{background:#eee;padding:2px 6px;border-radius:4px}</style></head>` +
          `<body><h1>Notes</h1><p>Served by region: <code>${REGION}</code>${READ_ONLY ? ' <b>(read-only DR replica)</b>' : ''}</p>` +
          `<p>API: <code>/api/healthz</code>, <code>/api/whoami</code>, <code>/api/notes</code></p></body></html>`
      );
    }
    return json(res, 404, { error: 'not found' });
  } catch (e) {
    return json(res, 500, { error: String(e.message || e) });
  }
});

ensureSchema()
  .catch((e) => console.error('schema init failed (continuing):', e.message))
  .finally(() => server.listen(PORT, () => console.log(`notes-api listening on ${PORT} region=${REGION} readOnly=${READ_ONLY}`)));
