resource "azurerm_key_vault" "main" {
  name                       = "kv-s3-${var.region_short}-${var.instance}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}

# Let the operator running Terraform write the secret.
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "pg_password" {
  name         = "pg-admin-password"
  value        = random_password.pg.result
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.tags

  depends_on = [azurerm_role_assignment.kv_admin]

  lifecycle { ignore_changes = [tags["created_date"]] }
}
