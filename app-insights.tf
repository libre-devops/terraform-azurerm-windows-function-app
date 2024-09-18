resource "azurerm_application_insights" "app_insights_workspace" {
  for_each = { for app in var.windows_function_apps : app.name => app if app.create_new_app_insights == true && app.workspace_id != null }

  name                                  = each.value.app_insights_name != null ? each.value.app_insights_name : "appi-${each.value.name}"
  location                              = each.value.location
  resource_group_name                   = each.value.rg_name
  workspace_id                          = each.value.workspace_id
  application_type                      = var.app_insights_type
  daily_data_cap_in_gb                  = var.app_insights_daily_cap_in_gb
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notifications_disabled
  internet_ingestion_enabled            = try(var.app_insights_internet_ingestion_enabled, null)
  internet_query_enabled                = try(var.app_insights_internet_query_enabled, null)
  local_authentication_disabled         = try(var.app_insights_local_authentication_disabled, true)
  force_customer_storage_for_profiler   = try(var.app_insights_force_customer_storage_for_profile, false)
  sampling_percentage                   = try(var.app_insights_sampling_percentage, 100)
  tags                                  = try(var.tags, null)
}

locals {
  app_insights_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY        = element(azurerm_application_insights.app_insights_workspace.*.instrumentation_key, 0),
    APPLICATIONINSIGHTS_CONNECTION_STRING = element(azurerm_application_insights.app_insights_workspace.*.connection_string, 0)
  }

  app_insights_settings_map = tomap(local.app_insights_settings)
}
