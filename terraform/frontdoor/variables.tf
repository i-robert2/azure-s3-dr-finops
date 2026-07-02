variable "subscription_id" {
  type    = string
  default = "d5e040e6-7342-40d6-acec-25f9a41d060a"
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

# The two ingress hostnames (e.g. app-<ip>.sslip.io) — set after ingress is up.
variable "primary_origin_host" {
  type = string
}

variable "dr_origin_host" {
  type = string
}

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
