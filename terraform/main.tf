resource "azurerm_resource_group" "LogicApps" {
  name     = var.logic_app_rg
  location = var.resource_location
}

resource "azurerm_storage_account" "EntraMonitorStorageAccount" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.LogicApps.name
  location                 = var.resource_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_resource_group_template_deployment" "EntraSecretMonitorTemplate" {
  name                = var.entra_secret_monitor_name
  resource_group_name = azurerm_resource_group.LogicApps.name
  deployment_mode     = "Incremental"

  template_content = file("${path.module}/entra-app-workflow.json")

  parameters_content = jsonencode({
    "$connections" = {
      "value" = {
        "azureblob" = {
          "connectionId"   = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.LogicApps.name}/providers/Microsoft.Web/connections/azureblob",
          "connectionName" = "azureblob",
          "id"             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.resource_location}/managedApis/azureblob",
          "connectionProperties" = {
            "authentication" = {
              "type" = "ManagedServiceIdentity"
            }
          }
        }
      }
    }
  })
}

data "azurerm_logic_app_workflow" "EntraSecretMonitor" {
  name                = "entra-secret-monitor"
  resource_group_name = azurerm_resource_group.LogicApps.name

  depends_on = [azurerm_resource_group_template_deployment.EntraSecretMonitorTemplate]
}

resource "azurerm_role_assignment" "MonitorStorageAccess" {
  scope                = azurerm_storage_account.EntraMonitorStorageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_logic_app_workflow.EntraSecretMonitor.identity[0].principal_id
}
