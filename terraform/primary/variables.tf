variable "subscription_id" {
  type    = string
  default = "d5e040e6-7342-40d6-acec-25f9a41d060a"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "swedencentral"
}

variable "region_short" {
  type    = string
  default = "sdc"
}

variable "instance" {
  type    = string
  default = "001"
}

variable "owner" {
  type    = string
  default = "i-robert2"
}

variable "cost_center" {
  type    = string
  default = "platform-eng"
}

variable "keep_until" {
  type    = string
  default = "2026-07-09"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}

# GeneralPurpose is required for cross-region read replicas (Burstable can't be a source).
variable "pg_sku" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "pg_admin_login" {
  type    = string
  default = "pgadmin"
}

variable "vnet_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

# Remote-state backend coordinates (shared stack outputs).
variable "tfstate_rg" {
  type    = string
  default = "rg-tfstate"
}

variable "tfstate_sa" {
  type    = string
  default = "sttfstate22601"
}

variable "tfstate_container" {
  type    = string
  default = "tfstate"
}
