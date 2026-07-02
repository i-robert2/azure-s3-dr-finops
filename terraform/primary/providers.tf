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

# The shared stack owns the Premium ACR; we read its id to grant AcrPull.
data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_rg
    storage_account_name = var.tfstate_sa
    container_name       = var.tfstate_container
    key                  = "s3-shared.tfstate"
  }
}
