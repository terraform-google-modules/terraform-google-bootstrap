/**
 * Copyright 2024 Google LLC
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
  create_cloudbuild_sa = var.cloudbuild_sa == ""
  cloudbuild_sa        = local.create_cloudbuild_sa ? google_service_account.cb_sa[0].id : var.cloudbuild_sa
  // Service account format is projects/PROJECT_ID/serviceAccounts/SERVICE_ACCOUNT_EMAIL
  cloudbuild_sa_email     = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 1)
  create_infra_manager_sa = var.infra_manager_sa == ""
  im_sa                   = local.create_infra_manager_sa ? google_service_account.im_sa[0].id : var.infra_manager_sa
  im_sa_email             = element(split("/", local.im_sa), length(split("/", local.im_sa)) - 1)
}

resource "google_service_account" "cb_sa" {
  count                        = local.create_cloudbuild_sa ? 1 : 0
  project                      = var.project_id
  account_id                   = trimsuffix(substr(var.custom_cloudbuild_sa_name != "" ? var.custom_cloudbuild_sa_name : "cb-sa-${random_id.resources_random_id.dec}-${local.default_prefix}", 0, 30), "-")
  description                  = "SA used for Cloud Build triggers invoking Infrastructure Manager."
  create_ignore_already_exists = true
}

# https://cloud.google.com/infrastructure-manager/docs/configure-service-account
resource "google_project_iam_member" "cb_config_admin_role" {
  count   = local.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role    = "roles/config.admin"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_project_iam_member" "cb_config_agent_role" {
  count   = local.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role    = "roles/config.agent"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Allow trigger logs to be written
resource "google_project_iam_member" "cb_logWriter_role" {
  count   = local.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Allows the Cloud Build service account to act as the Infra Manger service account
resource "google_project_iam_member" "cb_serviceAccountUser_role" {
  count   = local.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_project_iam_member" "cb_storage_objects_viewer" {
  count   = local.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_service_account" "im_sa" {
  count                        = local.create_infra_manager_sa ? 1 : 0
  project                      = var.project_id
  account_id                   = trimsuffix(substr(var.custom_infra_manager_sa_name != "" ? var.custom_infra_manager_sa_name : "im-sa-${random_id.resources_random_id.dec}-${local.default_prefix}", 0, 30), "-")
  description                  = "SA used by Infrastructure Manager for actuating resources."
  create_ignore_already_exists = true
}

# https://cloud.google.com/infrastructure-manager/docs/configure-service-account
resource "google_project_iam_member" "im_config_agent_role" {
  count   = local.create_infra_manager_sa ? 1 : 0
  project = var.project_id
  role    = "roles/config.agent"
  member  = "serviceAccount:${local.im_sa_email}"
}

# https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
resource "google_project_iam_member" "im_sa_logging" {
  count   = local.create_infra_manager_sa ? 1 : 0
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.im_sa_email}"
}

resource "google_project_iam_member" "im_sa_roles" {
  for_each = toset(var.infra_manager_sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${local.im_sa_email}"
}
