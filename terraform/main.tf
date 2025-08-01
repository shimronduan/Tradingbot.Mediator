resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "st${var.function_app_name}${random_string.random.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = "plan-${var.function_app_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "function_app" {
  name                = "func-${var.function_app_name}-${random_string.random.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "AzureWebJobsStorage" = azurerm_storage_account.sa.primary_connection_string
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
  }
}

output "function_app_name" {
  value = azurerm_windows_function_app.function_app.name
}
