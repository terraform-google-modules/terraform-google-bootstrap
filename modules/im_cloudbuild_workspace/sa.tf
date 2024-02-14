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
  cloudbuild_sa = var.create_cloudbuild_sa ? google_service_account.cb_sa[0].id : var.cloudbuild_sa
  cloudbuild_sa_email = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 1)
  im_sa = var.create_infra_manager_sa ? google_service_account.im_sa[0].id : var.infra_manager_sa
  im_sa_email = element(split("/", local.im_sa), length(split("/", local.im_sa)) - 1)

  # Optional roles for IM SA
  im_sa_roles_expand = merge(
    [for project_name, pr in var.infra_manager_sa_roles :
      { for role in pr.roles : "${project_name}/${role}" =>
        {
          project_id = pr.project_id, role = role
        }
      }
    ]...
  )
}

resource "google_service_account" "cb_sa" {
  count = var.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  account_id = substr(var.create_cloudbuild_sa_name != "" ? var.create_cloudbuild_sa_name : "cb-sa-${local.default_prefix}", 0, 30)
    # TODO Come up with better description?
  description = "SA for creating Cloud Build triggers."
}

# https://cloud.google.com/infrastructure-manager/docs/configure-service-account
resource "google_project_iam_member" "cb_config_admin_role" {
  count = var.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role = "roles/config.admin"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Allow trigger logs to be written
resource "google_project_iam_member" "cb_logWriter_role" {
  count = var.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role = "roles/logging.logWriter"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

# Allows the Cloud Build service account to act as the Infra Manger service account
resource "google_project_iam_member" "cb_serviceAccountUser_role" {
  count = var.create_cloudbuild_sa ? 1 : 0
  project = var.project_id
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_service_account" "im_sa" {
  count = var.create_infra_manager_sa ? 1 : 0
  project = var.project_id
  account_id = substr(var.create_infra_manager_sa_name != "" ? var.create_infra_manager_sa_name : "im-sa-${local.default_prefix}", 0, 30)
  # TODO Come up with better description?
  description = "SA for Infrastructure Manager."
}

# https://cloud.google.com/infrastructure-manager/docs/configure-service-account
resource "google_project_iam_member" "im_config_agent_role" {
  count = var.create_infra_manager_sa ? 1 : 0
  project = var.project_id
  role = "roles/config.agent"
  member = "serviceAccount:${local.im_sa_email}"
}

# https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
resource "google_project_iam_member" "im_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.im_sa_email}"
}

resource "google_project_iam_member" "im_sa_roles" {
  for_each = local.im_sa_roles_expand
  project = each.value.project_id
  role = each.value.role
  member = "serviceAccount:${local.im_sa_email}"
}