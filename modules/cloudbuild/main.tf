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
  cloudbuild_project_id       = format("%s-%s-%s", var.project_prefix, "cloudbuild", random_id.suffix.hex)
  cloudbuild_apis             = ["cloudbuild.googleapis.com", "sourcerepo.googleapis.com", "cloudkms.googleapis.com"]
  impersonation_enabled_count = var.sa_enable_impersonation == true ? 1 : 0
  activate_apis               = distinct(concat(var.activate_apis, local.cloudbuild_apis))
  csr_repos                   = var.cloud_source_repos
}

resource "random_id" "suffix" {
  byte_length = 2
}

data "google_organization" "org" {
  organization = var.organization_id
}


/******************************************
  Cloudbuild project
*******************************************/

resource "google_project" "cloudbuild_project" {
  name                = local.cloudbuild_project_id
  project_id          = local.cloudbuild_project_id
  org_id              = var.organization_id
  billing_account     = var.billing_account
  auto_create_network = false
}

/******************************************
  Cloudbuild APIs
*******************************************/

resource "google_project_service" "cloudbuild_project_api" {
  for_each                   = toset(local.activate_apis)
  project                    = google_project.cloudbuild_project.id
  service                    = each.value
  disable_dependent_services = true
}

/******************************************
  Cloudbuild IAM for admins
*******************************************/

resource "google_project_iam_member" "org_admins_cloudbuild_editor" {
  project = google_project.cloudbuild_project.id
  role    = "roles/cloudbuild.builds.editor"
  member  = "group:${var.group_org_admins}"
}

resource "google_project_iam_member" "org_admins_cloudbuild_viewer" {
  project = google_project.cloudbuild_project.id
  role    = "roles/viewer"
  member  = "group:${var.group_org_admins}"
}

/******************************************
  Cloudbuild Artifact bucket
*******************************************/

resource "google_storage_bucket" "cloudbuild_artifacts" {
  project       = google_project.cloudbuild_project.id
  name          = format("%s-%s-%s", var.project_prefix, "cloudbuild-artifacts", random_id.suffix.hex)
  location      = var.default_region
  force_destroy = true
}

/******************************************
  KMS Keyring
 *****************************************/

resource "google_kms_key_ring" "tf_keyring" {
  project  = google_project.cloudbuild_project.id
  name     = "tf-keyring"
  location = var.default_region
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

/******************************************
  KMS Key
 *****************************************/

resource "google_kms_crypto_key" "tf_key" {
  name     = "tf-key"
  key_ring = google_kms_key_ring.tf_keyring.self_link
}

/******************************************
  Permissions to decrypt.
 *****************************************/

resource "google_kms_crypto_key_iam_binding" "cloudbuild_crypto_key_decrypter" {
  crypto_key_id = google_kms_crypto_key.tf_key.self_link
  role          = "roles/cloudkms.cryptoKeyDecrypter"

  members = [
    "serviceAccount:${google_project.cloudbuild_project.number}@cloudbuild.gserviceaccount.com",
    "serviceAccount:${var.terraform_sa_email}"
  ]
}

/******************************************
  Permissions for org admins to encrypt.
 *****************************************/

resource "google_kms_crypto_key_iam_binding" "cloud_build_crypto_key_encrypter" {
  crypto_key_id = google_kms_crypto_key.tf_key.self_link
  role          = "roles/cloudkms.cryptoKeyEncrypter"

  members = [
    "group:${var.group_org_admins}",
  ]
}

/******************************************
  Create Cloud Source Repos
*******************************************/

resource "google_sourcerepo_repository" "gcp_repo" {
  for_each = toset(var.cloud_source_repos)
  project  = google_project.cloudbuild_project.id
  name     = each.value
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

/******************************************
  Cloud Source Repo IAM
*******************************************/

resource "google_project_iam_member" "org_admins_source_repo_admin" {
  project = google_project.cloudbuild_project.id
  role    = "roles/source.admin"
  member  = "group:${var.group_org_admins}"
}

/***********************************************
 Cloud Build - Master branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "master_trigger" {
  for_each    = toset(var.cloud_source_repos)
  project     = google_project.cloudbuild_project.id
  description = "${each.value} - terraform apply on push to master."

  trigger_template {
    branch_name = "master"
    repo_name   = each.value
  }

  substitutions = {
    _ORG_ID               = var.organization_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _SEED_PROJECT_ID      = google_project.cloudbuild_project.id
  }

  filename = "cloudbuild-tf-apply.yaml"
  depends_on = [
    google_sourcerepo_repository.gcp_repo
  ]
}

/***********************************************
 Cloud Build - Non Master branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "non_master_trigger" {
  for_each    = toset(var.cloud_source_repos)
  project     = google_project.cloudbuild_project.id
  description = "${each.value} - terraform plan on all branches except master."

  trigger_template {
    branch_name = "[^master]"
    repo_name   = each.value
  }

  substitutions = {
    _ORG_ID               = var.organization_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _SEED_PROJECT_ID      = google_project.cloudbuild_project.id
  }

  filename = "cloudbuild-tf-plan.yaml"
  depends_on = [
    google_sourcerepo_repository.gcp_repo
  ]
}

/***********************************************
 Cloud Build - Terraform builder
 ***********************************************/

resource "null_resource" "cloudbuild_terraform_builder" {
  triggers = {
    project_id_seed_project = google_project.cloudbuild_project.id
  }

  provisioner "local-exec" {
    command = "gcloud builds submit ${path.module}/cloudbuild_builder/ --project ${google_project.cloudbuild_project.id} --config=${path.module}/cloudbuild_builder/cloudbuild.yaml"
  }

  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

/***********************************************
  Cloud Build - IAM
 ***********************************************/

resource "google_service_account_iam_member" "cloudbuild_terraform_sa_impersonate_permissions" {
  count              = local.impersonation_enabled_count
  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_project.cloudbuild_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

resource "google_organization_iam_member" "cloudbuild_serviceusage_consumer" {
  count  = local.impersonation_enabled_count
  org_id = var.organization_id
  role   = "roles/serviceusage.serviceUsageConsumer"
  member = "serviceAccount:${google_project.cloudbuild_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket = google_storage_bucket.cloudbuild_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_project.cloudbuild_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}

# Required to allow cloud build to access state with impersonation.
resource "google_storage_bucket_iam_member" "cloudbuild_state_iam" {
  count  = local.impersonation_enabled_count
  bucket = var.terraform_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_project.cloudbuild_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.cloudbuild_project_api
  ]
}