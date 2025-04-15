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
  cloudbuild_project_id = var.project_id != "" ? var.project_id : "tf-cloudbuild-"
  use_random_suffix     = var.project_id == ""

  basic_apis = [
    "cloudbuild.googleapis.com",
    "storage-api.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com"
  ]

  cloudbuild_apis = length(var.cloud_source_repos) > 0 ? concat(["sourcerepo.googleapis.com"], local.basic_apis) : local.basic_apis

  activate_apis = distinct(concat(var.activate_apis, local.cloudbuild_apis))
}

module "cloudbuild_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                        = local.cloudbuild_project_id
  random_project_id           = local.use_random_suffix
  disable_services_on_destroy = false
  folder_id                   = var.folder_id
  org_id                      = var.org_id
  billing_account             = var.billing_account
  activate_apis               = local.activate_apis
  labels                      = var.project_labels
  deletion_policy             = var.project_deletion_policy
  auto_create_network         = var.project_auto_create_network
}

// On the first run of cloud build submit, a bucket is automaticaly created with name "[PROJECT_ID]_cloudbuild"
// https://cloud.google.com/sdk/gcloud/reference/builds/submit#:~:text=%5BPROJECT_ID%5D_cloudbuild
// This bucket is create in the default region "US"
// https://cloud.google.com/storage/docs/json_api/v1/buckets/insert#:~:text=or%20multi%2Dregion.-,Defaults%20to%20%22US%22,-.%20See%20Cloud%20Storage
// Creating the bucket beforehand make it is possible to define a custom location.
module "cloudbuild_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"

  name          = "${module.cloudbuild_project.project_id}_cloudbuild"
  project_id    = module.cloudbuild_project.project_id
  location      = var.location
  labels        = var.storage_bucket_labels
  force_destroy = var.buckets_force_destroy

  depends_on = [module.cloudbuild_project]
}

resource "google_sourcerepo_repository" "gcp_repo" {
  for_each = length(var.cloud_source_repos) > 0 ? toset(var.cloud_source_repos) : []

  project = module.cloudbuild_project.project_id
  name    = each.value
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
  count   = length(var.cloud_source_repos) > 0 ? 1 : 0
  project = module.cloudbuild_project.project_id
  role    = "roles/source.admin"
  member  = "group:${var.group_org_admins}"
}

//Cloudbuild Service Account
resource "google_storage_bucket_iam_member" "cloudbuild_iam" {
  bucket = module.cloudbuild_bucket.bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}
