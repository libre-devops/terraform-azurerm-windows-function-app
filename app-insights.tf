resource "azurerm_application_insights" "app_insights_workspace" {
  for_each = {
    for app in var.windows_function_apps : app.name => app
    if app.create_new_app_insights == true && app.workspace_id != null && app.app_insights_name != null
  }

  name                                  = each.value.app_insights_name != null ? each.value.app_insights_name : "appi-${each.value.name}"
  location                              = each.value.location
  resource_group_name                   = each.value.rg_name
  workspace_id                          = each.value.workspace_id
  application_type                      = each.value.app_insights_type
  daily_data_cap_in_gb                  = each.value.app_insights_daily_cap_in_gb
  daily_data_cap_notifications_disabled = each.value.app_insights_daily_data_cap_notifications_disabled
  internet_ingestion_enabled            = try(each.value.app_insights_internet_ingestion_enabled, null)
  internet_query_enabled                = try(each.value.app_insights_internet_query_enabled, null)
  local_authentication_disabled         = try(each.value.app_insights_local_authentication_disabled, true)
  force_customer_storage_for_profiler   = try(each.value.app_insights_force_customer_storage_for_profile, false)
  sampling_percentage                   = try(each.value.app_insights_sampling_percentage, 100)
  tags                                  = try(each.value.tags, null)
}

locals {
  app_insights_map = {
    for app_insights in azurerm_application_insights.app_insights_workspace : app_insights.name => {
      APPINSIGHTS_INSTRUMENTATIONKEY        = app_insights.instrumentation_key,
      APPLICATIONINSIGHTS_CONNECTION_STRING = app_insights.connection_string
    }
  }
}
