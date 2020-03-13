variable "organization" {
  type = string
  default = "Theatreers"
}

variable "name" {
  type = string
}

variable "scope" {
  type = string
}

data "azurerm_client_config" "current" {
}

# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "~> 0.3"
}

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  features {}
}

# Generate a random password for the service principal
resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

# Create an application
resource "azuread_application" "example" {
  name = "${var.organization}-${var.name}-SP"
}

# Create a service principal
resource "azuread_service_principal" "example" {
  application_id = azuread_application.example.application_object_id
}

# Create a service principal secret
resource "azuread_application_password" "example" {
  application_id    = azuread_application.example.id
  value             = random_password.password.result
  end_date_relative = "8760h"
}

resource "azurerm_role_assignment" "example" {
  scope                = var.scope
  role_definition_name = "Contributor"
  principal_id         = azuread_application.example.application_id
}

# Configure the Terraform Enterprise Provider
# TFE Provider defaults to the app.terraform.io endpoint, override if you have your own TFE deployment
# Token is brought in as TFE_TOKEN environment variable
provider "tfe" {}

# Create the resource
resource "tfe_workspace" "workspace" {
  name         = var.name
  organization = var.organization
}

resource "tfe_variable" "client_id" {
  key          = "ARM_CLIENT_ID"
  value        = azuread_application.example.id
  category     = "env"
  workspace_id = tfe_workspace.workspace.id
  description  = "Azure AD Service Principal Client ID for ${var.name} workspace"
  sensitive    = false
}

resource "tfe_variable" "subscription_id" {
  key          = "ARM_SUBSCRIPTION_ID"
  value        = var.scope
  category     = "env"
  workspace_id = tfe_workspace.workspace.id
  description  = "Azure Subscription ID for ${var.name} workspace"
  sensitive    = false
}

resource "tfe_variable" "tenant_id" {
  key          = "ARM_TENANT_ID"
  value        = data.azurerm_client_config.current.tenant_id
  category     = "env"
  workspace_id = tfe_workspace.workspace.id
  description  = "Azure Tenant ID for ${var.name} workspace"
  sensitive    = false
}

resource "tfe_variable" "client_secret" {
  key          = "ARM_CLIENT_SECRET"
  value        = random_password.password.result
  category     = "env"
  workspace_id = tfe_workspace.workspace.id
  description  = "Azure AD Service Principal Client Secret for ${var.name} workspace"
  sensitive    = false
}
