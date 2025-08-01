variable "function_app_name" {
  description = "The name of the function app."
  type        = string
  default     = "trading-bot-v3"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "trading-bot-v3"
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "West Europe"
}
