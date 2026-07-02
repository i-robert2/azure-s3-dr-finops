# Subscription budget with alerts at 50 / 80 / 100 % of the monthly cap.
# Notifications fire (email) when actual spend crosses each threshold.
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-s3-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-07-01T00:00:00Z"
    end_date   = "2027-07-01T00:00:00Z"
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_emails = [var.alert_email]
    }
  }
}
