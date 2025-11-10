# ---------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. Licensed under the MIT license.
# ---------------------------------------------------------------------

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  default     = "swedencentral"
  nullable    = false
}

variable "resource_group_resource_id" {
  type        = string
  description = "The resource group resource id where the module resources will be deployed. If not provided, a new resource group will be created."
  default     = null
}

variable "sku" {
  type        = string
  description = "The SKU for the AI Foundry resource. The default is 'S0'."
  default     = "S0"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags to be applied to all resources."
}

variable "projects" {
  type = list(object({
    project_name         = string
    project_display_name = string
    project_description  = string
  }))
  description = "Collection of AI Foundry projects to create. Defaults to a single 'default-project'. Set to an empty list to create no project; override with multiple objects for multi-project deployments."
  default = [
    {
      project_name         = "default-project"
      project_display_name = "Default Project"
      project_description  = "Default Project description"
    }
  ]
}

variable "model_deployments" {
  description = "Override list of model deployment objects (name, version, format, optional sku { name, capacity }). Set to null to use module defaults (gpt-4_1, gpt-4o, o4_mini, text_embedding_3_large)."
  type = list(object({
    name    = string
    version = string
    format  = string
    sku = optional(object({
      name     = string
      capacity = number
    }))
  }))
  default  = null
  nullable = true
}

