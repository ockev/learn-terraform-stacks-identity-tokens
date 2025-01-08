terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40"  # or whichever exact version your code is written for
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"  # example
    }
  }
}

# features{}

provider "azuread" {
}

data "azurerm_subscription" "current" {}

resource "azuread_application" "tfc_application" {
  display_name = "tfc-application"
}

resource "azuread_service_principal" "tfc_service_principal" {
  # Requires the client (application) ID from the azuread_application
  client_id = azuread_application.tfc_application.app_id
}

resource "azurerm_role_assignment" "tfc_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azuread_service_principal.tfc_service_principal.object_id
  role_definition_name = "Contributor"
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
  # Takes the Object ID of the azuread_application (which is 'id' in TF)
  application_id       = azuread_application.tfc_application.id
  display_name         = "my-tfc-federated-credential-plan"
  audiences            = [var.tfc_azure_audience]
  issuer               = "https://${var.tfc_hostname}"
  subject              = "organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:deployment:${var.tfc_deployment}:operation:plan"
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
  application_id       = azuread_application.tfc_application.id
  display_name         = "my-tfc-federated-credential-apply"
  audiences            = [var.tfc_azure_audience]
  issuer               = "https://${var.tfc_hostname}"
  subject              = "organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:deployment:${var.tfc_deployment}:operation:apply"
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "client_id" {
  # This is the client/application ID from azuread_application
  value = azuread_application.tfc_application.app_id
}

output "tenant_id" {
  value = azuread_service_principal.tfc_service_principal.application_tenant_id
}
