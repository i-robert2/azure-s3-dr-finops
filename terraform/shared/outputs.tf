output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_id" {
  value = azurerm_container_registry.main.id
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "shared_resource_group" {
  value = azurerm_resource_group.shared.name
}
