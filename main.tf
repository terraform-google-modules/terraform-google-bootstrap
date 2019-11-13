/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  seed_project_id             = format("%s-%s-%s", var.project_prefix, "seed", random_id.suffix.hex)
  impersonation_apis          = distinct(concat(var.activate_apis, ["serviceusage.googleapis.com", "iamcredentials.googleapis.com"]))
  impersonation_enabled_count = var.sa_enable_impersonation == true ? 1 : 0
  activate_apis               = var.sa_enable_impersonation == true ? local.impersonation_apis : var.activate_apis
}

resource "random_id" "suffix" {
  byte_length = 2
}

data "google_organization" "org" {
  organization = var.organization_id
}

/******************************************
  Create IaC Project
*******************************************/

resource "google_project" "seed_project" {
  name                = local.seed_project_id
  project_id          = local.seed_project_id
  org_id              = var.organization_id
  billing_account     = var.billing_account
  auto_create_network = false
  depends_on = [
    google_organization_iam_member.org_admins_group,
  ]
}

resource "google_project_service" "seed_project_api" {
  for_each = toset(local.activate_apis)
  
  project                    = google_project.seed_project.id
  service                    = local.activate_apis[each.value]
  disable_dependent_services = true
}

/******************************************
  Service Account - Terraform for Org
*******************************************/

resource "google_service_account" "org_terraform" {
  project      = google_project.seed_project.id
  account_id   = "org-terraform"
  display_name = "CFT Organization Terraform Account"
}

/***********************************************
  GCS Bucket - Terraform State
 ***********************************************/

resource "google_storage_bucket" "org_terraform_state" {
  project       = google_project.seed_project.id
  name          = format("%s-%s-%s", var.project_prefix, "tfstate", random_id.suffix.hex)
  location      = var.default_region
  force_destroy = true
}

/***********************************************
  Authorative permissions at org. Required to
  remove default org wide permissions
  granting billing account and project creation.
 ***********************************************/

resource "google_organization_iam_binding" "billing_creator" {
  org_id = var.organization_id
  role   = "roles/billing.creator"

  members = [
    "group:${var.group_billing_admins}",
  ]
}

resource "google_organization_iam_binding" "project_creator" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.projectCreator"

  members = [
    "serviceAccount:${google_service_account.org_terraform.email}",
    "group:${var.group_org_admins}"
  ]
}

/***********************************************
  Organization permissions for org admins.
 ***********************************************/

resource "google_organization_iam_member" "org_admins_group" {
  for_each = toset(var.org_admins_org_iam_permissions)
  
  org_id = var.organization_id
  role   = var.org_admins_org_iam_permissions[each.value]
  member = "group:${var.group_org_admins}"
}

/***********************************************
  Organization permissions for billing admins.
 ***********************************************/

resource "google_organization_iam_member" "org_billing_admin" {
  org_id = var.organization_id
  role   = "roles/billing.admin"
  member = "group:${var.group_billing_admins}"
}

/***********************************************
  Organization permissions for Terraform.
 ***********************************************/

resource "google_organization_iam_member" "tf_sa_org_perms" {
for_each = toset(var.sa_org_iam_permissions)

  org_id = var.organization_id
  role   = var.sa_org_iam_permissions[each.value]
  member = "serviceAccount:${google_service_account.org_terraform.email}"
}

resource "google_billing_account_iam_member" "tf_billing_user" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.org_terraform.email}"
}

resource "google_storage_bucket_iam_member" "org_terraform_state_iam" {
  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.org_terraform.email}"
}

/***********************************************
  IAM - Impersonation permissions to run terraform
  as org admin.
 ***********************************************/

resource "google_service_account_iam_member" "org_admin_sa_impersonate_permissions" {
  count = local.impersonation_enabled_count

  service_account_id = google_service_account.org_terraform.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:${var.group_org_admins}"
}

resource "google_organization_iam_member" "org_admin_serviceusage_consumer" {
  count = local.impersonation_enabled_count

  org_id     = var.organization_id
  role       = "roles/serviceusage.serviceUsageConsumer"
  member     = "group:${var.group_org_admins}"
  depends_on = [google_project_service.seed_project_api]
}
