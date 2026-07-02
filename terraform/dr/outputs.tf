output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "pg_replica_id" {
  value = azurerm_postgresql_flexible_server.replica.id
}

output "pg_fqdn" {
  value = azurerm_postgresql_flexible_server.replica.fqdn
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}
