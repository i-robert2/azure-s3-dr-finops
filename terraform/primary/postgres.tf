resource "random_password" "pg" {
  length           = 28
  special          = true
  override_special = "!#%*-_"
}

# Public access restricted to Azure-internal callers. Cross-region read replicas
# need the replica (in another region/VNet) to reach the source on 5432; the
# public endpoint + an "allow Azure services" firewall rule is the reliable
# pattern (private access would require cross-region VNet peering + dual
# private-DNS links). See docs/ADRs and the README "Issues we hit".
resource "azurerm_postgresql_flexible_server" "primary" {
  name                          = "pg-${local.base}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "16"
  sku_name                      = var.pg_sku
  storage_mb                    = 32768
  administrator_login           = var.pg_admin_login
  administrator_password        = random_password.pg.result
  public_network_access_enabled = true
  zone                          = "1"
  backup_retention_days         = 7
  tags                          = local.tags

  lifecycle {
    ignore_changes = [tags["created_date"], zone, high_availability[0].standby_availability_zone]
  }
}

# Allow other Azure services (the AKS clusters + the DR replica) to reach this
# server. The special 0.0.0.0-0.0.0.0 range means "Azure services only".
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.primary.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "notes" {
  name      = "notes"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
