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
  seed_project_id             = format("%s-%s", var.project_prefix, "seed")
  impersonation_apis          = distinct(concat(var.activate_apis, ["serviceusage.googleapis.com", "iamcredentials.googleapis.com"]))
  impersonation_enabled_count = var.sa_enable_impersonation == true ? 1 : 0
  activate_apis               = var.sa_enable_impersonation == true ? local.impersonation_apis : var.activate_apis
  org_project_creators        = distinct(concat(var.org_project_creators, ["serviceAccount:${google_service_account.org_terraform.email}", "group:${var.group_org_admins}"]))
  is_organization             = var.parent_folder == "" ? true : false
  parent_id                   = var.parent_folder == "" ? var.org_id : split("/", var.parent_folder)[1]
  seed_org_depends_on         = ! local.is_organization && try(google_folder_iam_member.tmp_project_creator.0.etag,false) ? var.org_id : google_organization_iam_member.tmp_project_creator.0.org_id
}

resource "random_id" "suffix" {
  byte_length = 2
}

/*************************************************
  Make sure group_org_admins has projectCreator.
*************************************************/

resource "google_organization_iam_member" "tmp_project_creator" {
  count  = local.is_organization ? 1 : 0
  org_id = local.parent_id
  role   = "roles/resourcemanager.projectCreator"
  member = "group:${var.group_org_admins}"
}

resource "google_folder_iam_member" "tmp_project_creator" {
  count  = local.is_organization ? 0 : 1
  folder = local.parent_id
  role   = "roles/resourcemanager.projectCreator"
  member = "group:${var.group_org_admins}"
}

/******************************************
  Create IaC Project
*******************************************/

module "seed_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 8.0"
  name                        = local.seed_project_id
  random_project_id           = true
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = local.seed_org_depends_on
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = var.project_labels
  skip_gcloud_download        = var.skip_gcloud_download
}

/******************************************
  Service Account - Terraform for Org
*******************************************/

resource "google_service_account" "org_terraform" {
  project      = module.seed_project.project_id
  account_id   = "org-terraform"
  display_name = "CFT Organization Terraform Account"
}

/***********************************************
  GCS Bucket - Terraform State
 ***********************************************/

resource "google_storage_bucket" "org_terraform_state" {
  project            = module.seed_project.project_id
  name               = format("%s-%s-%s", var.project_prefix, "tfstate", random_id.suffix.hex)
  location           = var.default_region
  labels             = var.storage_bucket_labels
  bucket_policy_only = true
  versioning {
    enabled = true
  }
}

/***********************************************
  Authorative permissions at org. Required to
  remove default org wide permissions
  granting billing account and project creation.
 ***********************************************/

resource "google_organization_iam_binding" "billing_creator" {
  org_id = var.org_id
  role   = "roles/billing.creator"
  members = [
    "group:${var.group_billing_admins}",
  ]
}

resource "google_organization_iam_binding" "project_creator" {
  count   = local.is_organization ? 1 : 0
  org_id  = local.parent_id
  role    = "roles/resourcemanager.projectCreator"
  members = local.org_project_creators
}

resource "google_folder_iam_binding" "project_creator" {
  count   = local.is_organization ? 0 : 1
  folder  = local.parent_id
  role    = "roles/resourcemanager.projectCreator"
  members = local.org_project_creators
}

/***********************************************
  Organization permissions for org admins.
 ***********************************************/

resource "google_organization_iam_member" "org_admins_group" {
  for_each = toset(var.org_admins_org_iam_permissions)
  org_id   = var.org_id
  role     = each.value
  member   = "group:${var.group_org_admins}"
}

/***********************************************
  Organization permissions for billing admins.
 ***********************************************/

resource "google_organization_iam_member" "org_billing_admin" {
  org_id = var.org_id
  role   = "roles/billing.admin"
  member = "group:${var.group_billing_admins}"
}

/***********************************************
  Organization permissions for Terraform.
 ***********************************************/

resource "google_organization_iam_member" "tf_sa_org_perms" {
  for_each = toset(var.sa_org_iam_permissions)

  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.org_terraform.email}"
}

resource "google_billing_account_iam_member" "tf_billing_user" {
  count              = var.grant_billing_user == true ? 1 : 0
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.org_terraform.email}"
}

resource "google_storage_bucket_iam_member" "org_terraform_state_iam" {
  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
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
  count = var.sa_enable_impersonation && local.is_organization ? 1 : 0

  org_id = local.parent_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "group:${var.group_org_admins}"
}

resource "google_folder_iam_member" "org_admin_serviceusage_consumer" {
  count = var.sa_enable_impersonation && ! local.is_organization ? 1 : 0

  folder = local.parent_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "group:${var.group_org_admins}"
}

resource "google_storage_bucket_iam_member" "orgadmins_state_iam" {
  count = local.impersonation_enabled_count

  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "group:${var.group_org_admins}"
}
