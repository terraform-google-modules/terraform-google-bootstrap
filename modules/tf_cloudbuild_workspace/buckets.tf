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


# Custom bucket for storing build logs when user provided SA is used. This is also used for storing plan artifacts.
# https://cloud.google.com/build/docs/securing-builds/store-manage-build-logs#store-custom-bucket

locals {
  # selflink of form https://www.googleapis.com/storage/v1/b/bucket-name
  state_bucket_self_link = var.create_state_bucket ? module.state_bucket[0].bucket.self_link : var.state_bucket_self_link
  state_bucket_name      = split("/", local.state_bucket_self_link)[length(split("/", local.state_bucket_self_link)) - 1]
  log_bucket_name        = split("/", module.log_bucket.bucket.self_link)[length(split("/", module.log_bucket.bucket.self_link)) - 1]
  artifacts_bucket_name  = split("/", module.artifacts_bucket.bucket.self_link)[length(split("/", module.artifacts_bucket.bucket.self_link)) - 1]
}


module "artifacts_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"

  name          = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : "${local.default_prefix}-build-artifacts-${var.project_id}"
  project_id    = var.project_id
  location      = var.location
  force_destroy = var.buckets_force_destroy
}

resource "google_storage_bucket_iam_member" "artifacts_admin" {
  bucket = module.artifacts_bucket.bucket.self_link
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

module "log_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"

  name          = var.log_bucket_name != "" ? var.log_bucket_name : "${local.default_prefix}-build-logs-${var.project_id}"
  project_id    = var.project_id
  location      = var.location
  force_destroy = var.buckets_force_destroy
}

resource "google_storage_bucket_iam_member" "log_admin" {
  bucket = module.log_bucket.bucket.self_link
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Custom bucket for storing TF state
module "state_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 9.0"
  count   = var.create_state_bucket ? 1 : 0

  name          = var.create_state_bucket_name != "" ? var.create_state_bucket_name : "${local.default_prefix}-build-state-${var.project_id}"
  project_id    = var.project_id
  location      = var.location
  force_destroy = var.buckets_force_destroy
}

resource "google_storage_bucket_iam_member" "state_admin" {
  bucket = local.state_bucket_self_link
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}
