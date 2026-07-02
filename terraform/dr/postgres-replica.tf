# Cross-region read replica of the primary Postgres. It follows the primary
# asynchronously; on failover it is promoted to a standalone read-write server.
resource "azurerm_postgresql_flexible_server" "replica" {
  name                          = "pg-${local.base}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  create_mode                   = "Replica"
  source_server_id              = data.terraform_remote_state.primary.outputs.pg_primary_id
  public_network_access_enabled = true
  zone                          = "1"
  tags                          = local.tags

  lifecycle {
    ignore_changes = [
      tags["created_date"],
      zone,
      high_availability,
      administrator_login,
      administrator_password,
      version,
      sku_name,
      storage_mb,
    ]
  }
}

# Let the DR AKS app reach the replica (and, post-promotion, write to it).
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.replica.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
