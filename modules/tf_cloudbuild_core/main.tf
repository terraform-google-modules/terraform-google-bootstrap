/**
 * Copyright 2022 Google LLC
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
  cloudbuild_project_id = var.project_id != "" ? var.project_id : format("%s-%s", var.project_prefix, "cloudbuild")

  cloudbuild_apis = [
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com"
  ]

  activate_apis = distinct(concat(var.activate_apis, local.cloudbuild_apis))
}

resource "random_id" "suffix" {
  byte_length = 2
}

module "cloudbuild_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 13.0"

  name                        = local.cloudbuild_project_id
  random_project_id           = var.random_suffix
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = var.project_labels
}

module "cloudbuild_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 3.2"

  name          = "${module.cloudbuild_project.project_id}_cloudbuild"
  project_id    = module.cloudbuild_project.project_id
  location      = var.location
  labels        = var.storage_bucket_labels
  force_destroy = var.buckets_force_destroy
}

module "cloudbuild_artifacts" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 3.2"

  name          = "${var.project_prefix}-cloudbuild-artifacts-${random_id.suffix.hex}"
  project_id    = module.cloudbuild_project.project_id
  location      = var.location
  labels        = var.storage_bucket_labels
  force_destroy = var.buckets_force_destroy
}

resource "google_sourcerepo_repository" "gcp_repo" {
  for_each = var.create_cloud_source_repos ? toset(var.cloud_source_repos) : []

  project = module.cloudbuild_project.project_id
  name    = each.value
}

resource "google_cloudbuild_worker_pool" "private_pool" {
  count = var.create_worker_pool ? 1 : 0

  name     = "private-cb-pool-${random_id.suffix.hex}"
  project  = module.cloudbuild_project.project_id
  location = var.location

  worker_config {
    disk_size_gb   = var.worker_pool_disk_size_gb
    machine_type   = var.worker_pool_machine_type
    no_external_ip = var.worker_pool_no_external_ip
  }
}

module "allowed_worker_pools" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"
  count   = var.create_worker_pool ? 1 : 0

  project_id        = module.cloudbuild_project.project_id
  policy_for        = "project"
  policy_type       = "list"
  allow             = ["under:projects/${module.cloudbuild_project.project_id}"]
  allow_list_length = "1"
  constraint        = "constraints/cloudbuild.allowedWorkerPools"
}

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

resource "google_project_iam_member" "org_admins_source_repo_admin" {
  count   = var.create_cloud_source_repos ? 1 : 0
  project = module.cloudbuild_project.project_id
  role    = "roles/source.admin"
  member  = "group:${var.group_org_admins}"
}

resource "google_storage_bucket_iam_member" "cloudbuild_artifacts_iam" {
  bucket = module.cloudbuild_artifacts.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "cloudbuild_iam" {
  bucket = module.cloudbuild_bucket.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}
