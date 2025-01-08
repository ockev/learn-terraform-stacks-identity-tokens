terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}



provider "azurerm" {
  features {}
}

provider "azuread" {
}

data "azurerm_subscription" "current" {}

resource "azuread_application" "tfc_application" {
  display_name = "tfc-application"
}

resource "azuread_service_principal" "tfc_service_principal" {
  # v2.x expects "client_id" and azuread_application exports "app_id"
  client_id = azuread_application.tfc_application.application_id
}

resource "azurerm_role_assignment" "tfc_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  principal_id         = azuread_service_principal.tfc_service_principal.object_id
  role_definition_name = "Contributor"
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
  # For federated credentials, "application_id" wants the Object ID => azuread_application.tfc_application.id
  application_id = azuread_application.tfc_application.id
  display_name   = "my-tfc-federated-credential-plan"
  audiences      = [var.tfc_azure_audience]
  issuer         = "https://${var.tfc_hostname}"
  subject        = "organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:deployment:${var.tfc_deployment}:operation:plan"
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
  application_id = azuread_application.tfc_application.id
  display_name   = "my-tfc-federated-credential-apply"
  audiences      = [var.tfc_azure_audience]
  issuer         = "https://${var.tfc_hostname}"
  subject        = "organization:${var.tfc_organization}:project:${var.tfc_project}:stack:${var.tfc_stack}:deployment:${var.tfc_deployment}:operation:apply"
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "client_id" {
  # The Azure AD "client" ID is "app_id" in v2.x
  value = azuread_application.tfc_application.application_id
}

output "tenant_id" {
  value = azuread_service_principal.tfc_service_principal.application_tenant_id
}
