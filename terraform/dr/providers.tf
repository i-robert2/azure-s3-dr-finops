provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_rg
    storage_account_name = var.tfstate_sa
    container_name       = var.tfstate_container
    key                  = "s3-shared.tfstate"
  }
}

# The DR Postgres is a read replica of the primary; read its server id + creds.
data "terraform_remote_state" "primary" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_rg
    storage_account_name = var.tfstate_sa
    container_name       = var.tfstate_container
    key                  = "s3-primary.tfstate"
  }
}
