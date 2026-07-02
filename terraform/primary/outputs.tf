output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "pg_primary_id" {
  value = azurerm_postgresql_flexible_server.primary.id
}

output "pg_fqdn" {
  value = azurerm_postgresql_flexible_server.primary.fqdn
}

output "pg_database" {
  value = azurerm_postgresql_flexible_server_database.notes.name
}

output "pg_admin_login" {
  value = var.pg_admin_login
}

output "pg_admin_password" {
  value     = random_password.pg.result
  sensitive = true
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}
