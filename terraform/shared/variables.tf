variable "subscription_id" {
  type    = string
  default = "d5e040e6-7342-40d6-acec-25f9a41d060a"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "primary_region" {
  type    = string
  default = "swedencentral"
}

variable "dr_region" {
  type    = string
  default = "polandcentral"
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

# Monthly subscription spend cap the budget tracks (EUR/USD as billed).
variable "budget_amount" {
  type    = number
  default = 150
}

# Email that receives budget threshold alerts (50/80/100%).
variable "alert_email" {
  type    = string
  default = "i-robert2@users.noreply.github.com"
}
