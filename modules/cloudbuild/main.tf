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
  cloudbuild_project_id       = var.project_id != "" ? var.project_id : format("%s-%s", var.project_prefix, "cloudbuild")
  gar_repo_name               = var.gar_repo_name != "" ? var.gar_repo_name : format("%s-%s", var.project_prefix, "tf-runners")
  impersonation_enabled_count = var.sa_enable_impersonation == true ? 1 : 0
  activate_apis               = distinct(concat(var.activate_apis, local.cloudbuild_apis))
  apply_branches_regex        = "^(${join("|", var.terraform_apply_branches)})$"
  gar_name                    = split("/", google_artifact_registry_repository.tf-image-repo.name)[length(split("/", google_artifact_registry_repository.tf-image-repo.name)) - 1]
  impersonate_service_account = var.impersonate_service_account != "" ? "--impersonate-service-account=${var.impersonate_service_account}" : ""
  basic_apis                  = ["cloudbuild.googleapis.com", "cloudkms.googleapis.com", "artifactregistry.googleapis.com"]
  cloudbuild_apis             = var.create_cloud_source_repos ? concat(["sourcerepo.googleapis.com"], local.basic_apis) : local.basic_apis
}

resource "random_id" "suffix" {
  byte_length = 2
}

/******************************************
  Cloudbuild project
*******************************************/

module "cloudbuild_project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 18.0"
  name                        = local.cloudbuild_project_id
  random_project_id           = var.random_suffix
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = var.project_labels
  deletion_policy             = var.project_deletion_policy
  auto_create_network         = var.project_auto_create_network
}

/******************************************
  Cloudbuild IAM for terraform SA
*******************************************/
// See https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts
// for details regarding the configuration of the Terraform service account to run Cloud Build

resource "google_project_iam_member" "terraform_sa_log_writer" {
  project = module.cloudbuild_project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_artifact_registry_repository_iam_member" "terraform_sa_artifact_registry_reader" {
  provider = google-beta

  project    = module.cloudbuild_project.project_id
  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_service_account_iam_member" "terraform_sa_self_impersonate" {
  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_service_account_iam_member" "terraform_sa_self_impersonate_token" {
  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_storage_bucket_iam_member" "terraform_sa_artifacts_iam" {
  bucket = google_storage_bucket.cloudbuild_artifacts.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_storage_bucket_iam_member" "terraform_sa_logs_iam" {
  bucket = google_storage_bucket.cloudbuild_logs.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.terraform_sa_email}"
}

resource "google_service_account_iam_member" "cloud_build_service_agent_sa_impersonate" {
  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${module.cloudbuild_project.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "time_sleep" "impersonate_propagation" {
  create_duration = "60s"

  depends_on = [
    google_service_account_iam_member.cloud_build_service_agent_sa_impersonate
  ]
}

/******************************************
  Cloudbuild IAM for admins
*******************************************/

resource "google_project_iam_member" "org_admins_cloudbuild_editor" {
  project = module.cloudbuild_project.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "group:${var.group_org_admins}"
}

resource "google_project_iam_member" "org_admins_cloudbuild_viewer" {
  project = module.cloudbuild_project.project_id
  role    = "roles/viewer"
  member  = "group:${var.group_org_admins}"
}

/******************************************
  Cloudbuild Logs bucket
*******************************************/

resource "google_storage_bucket" "cloudbuild_logs" {
  project  = module.cloudbuild_project.project_id
  name     = format("%s-%s-%s", module.cloudbuild_project.project_id, "cloudbuild-logs", random_id.suffix.hex)
  location = var.default_region
  labels   = var.storage_bucket_labels

  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
}

/******************************************
  Cloudbuild Artifact bucket
*******************************************/

resource "google_storage_bucket" "cloudbuild_artifacts" {
  project                     = module.cloudbuild_project.project_id
  name                        = format("%s-%s-%s", var.project_prefix, "cloudbuild-artifacts", random_id.suffix.hex)
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

/******************************************
  Create Cloud Source Repos
*******************************************/

resource "google_sourcerepo_repository" "gcp_repo" {
  for_each = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project  = module.cloudbuild_project.project_id
  name     = each.value
}

/******************************************
  Cloud Source Repo IAM
*******************************************/

resource "google_project_iam_member" "org_admins_source_repo_admin" {
  count   = var.create_cloud_source_repos ? 1 : 0
  project = module.cloudbuild_project.project_id
  role    = "roles/source.admin"
  member  = "group:${var.group_org_admins}"
}

/***********************************************
 Cloud Build - Main branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "main_trigger" {
  for_each        = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project         = module.cloudbuild_project.project_id
  description     = "${each.value} - terraform apply."
  service_account = var.terraform_sa_name

  trigger_template {
    branch_name = local.apply_branches_regex
    repo_name   = each.value
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _GAR_REPOSITORY       = local.gar_name
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _LOGS_BUCKET_NAME     = google_storage_bucket.cloudbuild_logs.name
    _TF_ACTION            = "apply"
  }

  filename = var.cloudbuild_apply_filename
  depends_on = [
    google_sourcerepo_repository.gcp_repo,
    google_service_account_iam_member.org_admin_terraform_sa_impersonate,
    time_sleep.impersonate_propagation
  ]
}

/***********************************************
 Cloud Build - Non Main branch triggers
 ***********************************************/

resource "google_cloudbuild_trigger" "non_main_trigger" {
  for_each        = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []
  project         = module.cloudbuild_project.project_id
  description     = "${each.value} - terraform plan."
  service_account = var.terraform_sa_name

  trigger_template {
    invert_regex = true
    branch_name  = local.apply_branches_regex
    repo_name    = each.value
  }

  substitutions = {
    _ORG_ID               = var.org_id
    _BILLING_ID           = var.billing_account
    _DEFAULT_REGION       = var.default_region
    _GAR_REPOSITORY       = local.gar_name
    _TF_SA_EMAIL          = var.terraform_sa_email
    _STATE_BUCKET_NAME    = var.terraform_state_bucket
    _ARTIFACT_BUCKET_NAME = google_storage_bucket.cloudbuild_artifacts.name
    _LOGS_BUCKET_NAME     = google_storage_bucket.cloudbuild_logs.name
    _TF_ACTION            = "plan"
  }

  filename = var.cloudbuild_plan_filename
  depends_on = [
    google_sourcerepo_repository.gcp_repo,
    google_service_account_iam_member.org_admin_terraform_sa_impersonate,
    time_sleep.impersonate_propagation
  ]
}

/***********************************************
 Cloud Build - Terraform Image Repo
 ***********************************************/
resource "google_artifact_registry_repository" "tf-image-repo" {
  provider = google-beta
  project  = module.cloudbuild_project.project_id

  location      = var.default_region
  repository_id = local.gar_repo_name
  description   = "Docker repository for Terraform runner images used by Cloud Build"
  format        = "DOCKER"
}

/***********************************************
 Cloud Build - Terraform builder
 ***********************************************/

resource "null_resource" "cloudbuild_terraform_builder" {
  triggers = {
    project_id_cloudbuild_project = module.cloudbuild_project.project_id
    terraform_version_sha256sum   = var.terraform_version_sha256sum
    terraform_version             = var.terraform_version
    gar_name                      = local.gar_name
    gar_location                  = google_artifact_registry_repository.tf-image-repo.location
  }

  provisioner "local-exec" {
    command = <<EOT
    gcloud ${local.impersonate_service_account} builds submit ${path.module}/cloudbuild_builder/ --project ${module.cloudbuild_project.project_id} --config=${path.module}/cloudbuild_builder/cloudbuild.yaml --substitutions=_GCLOUD_VERSION=${var.gcloud_version},_TERRAFORM_VERSION=${var.terraform_version},_TERRAFORM_VERSION_SHA256SUM=${var.terraform_version_sha256sum},_REGION=${google_artifact_registry_repository.tf-image-repo.location},_REPOSITORY=${local.gar_name}
  EOT
  }
  depends_on = [
    google_artifact_registry_repository_iam_member.terraform-image-iam
  ]
}

/***********************************************
  Cloud Build - IAM
 ***********************************************/

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket = google_storage_bucket.cloudbuild_artifacts.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "terraform-image-iam" {
  provider = google-beta
  project  = module.cloudbuild_project.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_service_account_iam_member" "org_admin_terraform_sa_impersonate" {
  count = local.impersonation_enabled_count

  service_account_id = var.terraform_sa_name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${var.group_org_admins}"
}
