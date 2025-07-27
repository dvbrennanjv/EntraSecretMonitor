resource "azurerm_resource_group" "LogicApps" {
  name = var.logic_app_rg
  location = var.resource_location
}

resource "azurerm_resource_group_template_deployment" "EntraLogicApp" {
  name = "logicapp-deployment"
  resource_group_name = azurerm_resource_group.LogicApps.name
  deployment_mode = "Incremental"
  template_content = file("${path.module}/entra-app-workflow.json")
  parameters_content = jsondecode({})
}

resource "azurerm_logic_app_workflow" "EntraSecretMonitor" {
  name = "entra-secret-monitor"
  location = var.resource_location
  resource_group_name = azurerm_resource_group.LogicApps.name
}