variable "organization_id" {
  description = "GCP Organization ID"
}

variable "billing_account" {
  description = "The ID of the billing account to associate projects with."
}

variable "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
}

variable "group_billing_admins" {
  description = "Google Group for GCP Billing Administrators"
}

variable "default_region" {
  description = "Default region to create resources where applicable."
}