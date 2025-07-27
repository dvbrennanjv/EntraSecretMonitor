resource "azurerm_resource_group" "LogicApps" {
  name = var.logic_app_rg
  location = var.resource_location
}