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
  seed_project_id            = var.project_id != "" ? var.project_id : format("%s-%s", var.project_prefix, "seed")
  generated_bucket_name      = var.random_suffix == true ? format("%s-%s-%s", var.project_prefix, "tfstate", random_id.suffix.hex) : format("%s-%s", var.project_prefix, "tfstate")
  supplied_bucket_name       = var.random_suffix == true ? format("%s-%s", var.state_bucket_name, random_id.suffix.hex) : var.state_bucket_name
  state_bucket_name          = var.state_bucket_name != "" ? local.supplied_bucket_name : local.generated_bucket_name
  base_apis                  = distinct(concat(var.activate_apis, var.encrypt_gcs_bucket_tfstate ? ["cloudkms.googleapis.com"] : []))
  impersonation_apis         = distinct(concat(local.base_apis, ["serviceusage.googleapis.com", "iamcredentials.googleapis.com"]))
  activate_apis              = var.sa_enable_impersonation == true ? local.impersonation_apis : local.base_apis
  org_project_creators_tf_sa = var.create_terraform_sa ? ["serviceAccount:${google_service_account.org_terraform[0].email}"] : []
  org_project_creators       = distinct(concat(var.org_project_creators, local.org_project_creators_tf_sa, ["group:${var.group_org_admins}"]))
  is_organization            = var.parent_folder == "" ? true : false
  parent_id                  = var.parent_folder == "" ? var.org_id : split("/", var.parent_folder)[1]
  seed_org_depends_on        = try(google_folder_iam_member.tmp_project_creator[0].etag, "") != "" ? var.org_id : google_organization_iam_member.tmp_project_creator[0].org_id
}

resource "random_id" "suffix" {
  byte_length = 2
}

/*************************************************
  Make sure group_org_admins has projectCreator.
*************************************************/

resource "google_organization_iam_member" "tmp_project_creator" {
  count = local.is_organization ? 1 : 0

  org_id = local.parent_id
  role   = "roles/resourcemanager.projectCreator"
  member = "group:${var.group_org_admins}"
}

resource "google_folder_iam_member" "tmp_project_creator" {
  count = local.is_organization ? 0 : 1

  folder = local.parent_id
  role   = "roles/resourcemanager.projectCreator"
  member = "group:${var.group_org_admins}"
}

/******************************************
  Create IaC Project
*******************************************/

module "seed_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 18.0"
  name                        = local.seed_project_id
  random_project_id           = var.random_suffix
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = local.seed_org_depends_on
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  create_project_sa           = false
  labels                      = var.project_labels
  lien                        = true
  deletion_policy             = var.project_deletion_policy
  auto_create_network         = var.project_auto_create_network
}

module "enable_cross_project_service_account_usage" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 6.0"

  project_id  = module.seed_project.project_id
  policy_for  = "project"
  policy_type = "boolean"
  enforce     = "false"
  constraint  = "constraints/iam.disableCrossProjectServiceAccountUsage"
}


/******************************************
  Service Account - Terraform for Org
*******************************************/

resource "google_service_account" "org_terraform" {
  count = var.create_terraform_sa ? 1 : 0

  project                      = module.seed_project.project_id
  account_id                   = var.tf_service_account_id
  display_name                 = var.tf_service_account_name
  create_ignore_already_exists = true
}

/***********************************************
  GCS Bucket - Terraform State
 ***********************************************/
data "google_storage_project_service_account" "gcs_account" {
  project = module.seed_project.project_id

  depends_on = [
    module.seed_project.project_id
  ]
}

module "kms" {
  count   = var.encrypt_gcs_bucket_tfstate ? 1 : 0
  source  = "terraform-google-modules/kms/google"
  version = "~> 3.2"

  project_id           = module.seed_project.project_id
  location             = var.default_region
  keyring              = "${var.project_prefix}-keyring"
  keys                 = ["${var.project_prefix}-key"]
  key_rotation_period  = var.key_rotation_period
  key_protection_level = var.key_protection_level
  set_decrypters_for   = ["${var.project_prefix}-key"]
  set_encrypters_for   = ["${var.project_prefix}-key"]
  decrypters = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
  encrypters = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
  prevent_destroy = var.kms_prevent_destroy
}

resource "google_storage_bucket" "org_terraform_state" {
  project                     = module.seed_project.project_id
  name                        = local.state_bucket_name
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.encrypt_gcs_bucket_tfstate ? ["encryption"] : []
    content {
      default_kms_key_name = module.kms[0].keys["${var.project_prefix}-key"]
    }
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
  count = local.is_organization ? 1 : 0

  org_id  = local.parent_id
  role    = "roles/resourcemanager.projectCreator"
  members = local.org_project_creators
}

resource "google_folder_iam_binding" "project_creator" {
  count = local.is_organization ? 0 : 1

  folder  = local.parent_id
  role    = "roles/resourcemanager.projectCreator"
  members = local.org_project_creators
}

/***********************************************
  Organization permissions for org admins.
 ***********************************************/

resource "google_organization_iam_member" "org_admins_group" {
  for_each = toset(var.org_admins_org_iam_permissions)

  org_id = var.org_id
  role   = each.value
  member = "group:${var.group_org_admins}"
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
  for_each = var.create_terraform_sa ? toset(var.sa_org_iam_permissions) : []

  org_id = var.org_id
  role   = each.value
  member = "serviceAccount:${google_service_account.org_terraform[0].email}"
}

resource "google_billing_account_iam_member" "tf_billing_user" {
  count = var.grant_billing_user && var.create_terraform_sa ? 1 : 0

  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.org_terraform[0].email}"
}

resource "google_storage_bucket_iam_member" "org_terraform_state_iam" {
  count = var.create_terraform_sa ? 1 : 0

  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.org_terraform[0].email}"
}

/***********************************************
  IAM - Impersonation permissions to run terraform
  as org admin.
 ***********************************************/

resource "google_service_account_iam_member" "org_admin_sa_user" {
  count = var.sa_enable_impersonation && var.create_terraform_sa ? 1 : 0

  service_account_id = google_service_account.org_terraform[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.group_org_admins}"
}

resource "google_service_account_iam_member" "org_admin_sa_impersonate_permissions" {
  count = var.sa_enable_impersonation && var.create_terraform_sa ? 1 : 0

  service_account_id = google_service_account.org_terraform[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:${var.group_org_admins}"
}

resource "google_organization_iam_member" "org_admin_serviceusage_consumer" {
  count = var.sa_enable_impersonation && local.is_organization ? 1 : 0

  org_id = local.parent_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "group:${var.group_org_admins}"
}

resource "google_folder_iam_member" "org_admin_service_account_user" {
  count = var.sa_enable_impersonation && !local.is_organization ? 1 : 0

  folder = local.parent_id
  role   = "roles/iam.serviceAccountUser"
  member = "group:${var.group_org_admins}"
}

resource "google_folder_iam_member" "org_admin_serviceusage_consumer" {
  count = var.sa_enable_impersonation && !local.is_organization ? 1 : 0

  folder = local.parent_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "group:${var.group_org_admins}"
}

resource "google_storage_bucket_iam_member" "orgadmins_state_iam" {
  count = var.sa_enable_impersonation ? 1 : 0

  bucket = google_storage_bucket.org_terraform_state.name
  role   = "roles/storage.admin"
  member = "group:${var.group_org_admins}"
}
