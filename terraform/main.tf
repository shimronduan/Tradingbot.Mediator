terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
  # You should set up a new, unique state file key for this project
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatesa17329"
    container_name       = "trading-bot-v2-tfstate"
    key                  = "tradingbot-mediator.terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = var.subscriptionId
  features {}
}

variable "subscriptionId" {
  description = "The Azure Subscription ID in which all resources in this example should be created."
}

variable "queueConnectionString" {
  description = "The connection string for the Azure Storage Queue."
}


# Find the existing resource group
data "azurerm_resource_group" "rg" {
  name = "trading-bot-v3-rg"
}

# Find the existing Linux App Service Plan
data "azurerm_service_plan" "asp" {
  name                = "trading-bot-app-v3-plan"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# --- New Resources for the .NET 8 Function App ---

# 1. Create a new, dedicated storage account for this function app
resource "azurerm_storage_account" "new" {
  name                     = "tradingbotmediatorsa" # Must be globally unique
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "tradingbotmediator-log-analytics"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 2. Create new Application Insights for monitoring this specific app
resource "azurerm_application_insights" "new" {
  name                = "Tradingbot-Mediator-insights"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  # Note: You might need a new Log Analytics workspace or can reuse an existing one
  # For simplicity, this example creates a new one.
}

# 3. Create the new .NET 8 Linux Function App
resource "azurerm_linux_function_app" "new" {
  name                = "Tradingbot-Mediator"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  # Link to the existing App Service Plan
  service_plan_id = data.azurerm_service_plan.asp.id

  # Link to the new storage account
  storage_account_name       = azurerm_storage_account.new.name
  storage_account_access_key = azurerm_storage_account.new.primary_access_key

  site_config {
    application_insights_key = azurerm_application_insights.new.instrumentation_key

    application_stack {
      dotnet_version = "8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.new.instrumentation_key,
    "FUNCTIONS_EXTENSION_VERSION"    = "~4"
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet-isolated" # Required for .NET 8 Function Apps
    "QUEUECONNECTION"                = var.queueConnectionString,
    # Add any other app settings your .NET app needs here
  }
}