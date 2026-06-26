resource "azurerm_network_watcher" "this" {
  name                = local.names.network_watcher
  location            = azurerm_resource_group.this["mgmt"].location
  resource_group_name = azurerm_resource_group.this["mgmt"].name
  tags                = local.tags
}

module "network_watcher" {
  source  = "Azure/avm-res-network-networkwatcher/azurerm"
  version = "0.3.2"

  network_watcher_id   = azurerm_network_watcher.this.id
  network_watcher_name = azurerm_network_watcher.this.name
  location             = azurerm_network_watcher.this.location
  resource_group_name  = azurerm_resource_group.this["mgmt"].name
  enable_telemetry     = var.enable_telemetry
  tags                 = local.tags

  flow_logs = {
    workload_nsg = {
      enabled            = true
      name               = "cfs-workload-nsg-flowlog-${local.region_code}"
      target_resource_id = module.workload_nsg.resource_id
      storage_account_id = module.storage_account.resource_id
      version            = 2
      retention_policy = {
        enabled = true
        days    = 30
      }
      traffic_analytics = {
        enabled               = true
        interval_in_minutes   = 10
        workspace_id          = module.log_analytics.resource.workspace_id
        workspace_region      = var.location
        workspace_resource_id = module.log_analytics.resource_id
      }
    }
  }
}

resource "azurerm_consumption_budget_resource_group" "lab" {
  for_each = azurerm_resource_group.this

  name              = "${each.value.name}-budget"
  resource_group_id = each.value.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }
}
