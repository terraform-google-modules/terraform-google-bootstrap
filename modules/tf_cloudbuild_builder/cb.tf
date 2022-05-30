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
  gar_uri             = "${var.gar_repo_location}-docker.pkg.dev/${var.project_id}/${local.gar_name}/${var.image_name}"
  cloudbuild_sa       = coalesce(var.cloudbuild_sa, google_service_account.cb_sa[0].id)
  cloudbuild_sa_email = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 1)
  # substitutions available in the CB trigger
  tags_subst = {
    "_TERRAFORM_FULL_VERSION"  = "1.1.0",
    "_TERRAFORM_MINOR_VERSION" = "1.1",
    "_TERRAFORM_MAJOR_VERSION" = "1",
  }
  img_tags_subst = [for tag in keys(local.tags_subst) : "${local.gar_uri}:v$${${tag}}"]

  # extract CSR project_id and repo name for granting reader access to CSR repo
  is_source_repo = var.dockerfile_repo_type == "CLOUD_SOURCE_REPOSITORIES"
  # url of form https://source.developers.google.com/p/<PROJECT_ID>/r/<REPO>
  source_repo_url_split = local.is_source_repo ? split("/", var.dockerfile_repo_uri) : []
  source_repo_project   = local.is_source_repo ? local.source_repo_url_split[4] : ""
  source_repo_name      = local.is_source_repo ? local.source_repo_url_split[6] : ""
}

resource "google_cloudbuild_trigger" "build_trigger" {
  project     = var.project_id
  name        = var.trigger_name
  description = "Builds a Terraform runner image. Managed by Terraform."
  source_to_build {
    uri       = var.dockerfile_repo_uri
    ref       = var.dockerfile_repo_ref
    repo_type = var.dockerfile_repo_type
  }

  # todo(bharathkkb): switch to yaml after https://github.com/hashicorp/terraform-provider-google/issues/9818
  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = concat(
        ["build"],
        [for img_tag in local.img_tags_subst : "--tag=${img_tag}"],
        ["--build-arg=TERRAFORM_VERSION=$${_TERRAFORM_FULL_VERSION}", "."]
      )
      dir = var.dockerfile_repo_dir != "" ? var.dockerfile_repo_dir : null
    }
    step {
      name = "${local.gar_uri}:v$${_TERRAFORM_FULL_VERSION}"
      args = ["version"]
    }
    images      = local.img_tags_subst
    logs_bucket = module.bucket.bucket.url
  }

  substitutions   = local.tags_subst
  service_account = local.cloudbuild_sa

  depends_on = [
    google_artifact_registry_repository_iam_member.push_images,
    google_project_iam_member.logs_writer
  ]
}

resource "google_service_account" "cb_sa" {
  count        = var.cloudbuild_sa == "" ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cb-builder-sa"
  display_name = "SA for Terraform builder build trigger. Managed by Terraform."
}

# https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Custom bucket for storing build logs when user provided SA is used
# https://cloud.google.com/build/docs/securing-builds/store-manage-build-logs#store-custom-bucket
module "bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 3.2"

  name          = "tf-cloudbuilder-build-logs-${var.project_id}"
  project_id    = var.project_id
  location      = var.gar_repo_location
  force_destroy = var.cb_logs_bucket_force_destroy
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = module.bucket.bucket.self_link
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

# allow CB SA to view source code if google source repo
resource "google_sourcerepo_repository_iam_member" "member" {
  count      = local.is_source_repo ? 1 : 0
  project    = local.source_repo_project
  repository = local.source_repo_name
  role       = "roles/viewer"
  member     = "serviceAccount:${local.cloudbuild_sa_email}"
}
