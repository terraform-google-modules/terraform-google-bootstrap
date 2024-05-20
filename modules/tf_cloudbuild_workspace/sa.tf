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
  # extract email from CB SA id form projects/{{project}}/serviceAccounts/{{email}}
  cloudbuild_sa       = var.create_cloudbuild_sa ? google_service_account.cb_sa[0].id : var.cloudbuild_sa
  cloudbuild_sa_email = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 1)
  worker_pool_project = var.enable_worker_pool ? element(split("/", var.worker_pool_id), index(split("/", var.worker_pool_id), "projects") + 1, ) : ""

  # Optional roles for CB SA
  cb_sa_roles_expand = merge(
    [for project_name, pr in var.cloudbuild_sa_roles :
      { for role in pr.roles : "${project_name}/${role}" =>
        {
          project_id = pr.project_id, role = role
        }
      }
    ]...
  )
}


resource "google_service_account" "cb_sa" {
  count                        = var.create_cloudbuild_sa ? 1 : 0
  project                      = var.project_id
  account_id                   = var.create_cloudbuild_sa_name != "" ? var.create_cloudbuild_sa_name : "tf-cb-${local.default_prefix}"
  display_name                 = "SA for Terraform build trigger ${local.default_prefix}. Managed by Terraform."
  create_ignore_already_exists = true
}

# https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
resource "google_project_iam_member" "cb_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_project_iam_member" "cb_sa_roles" {
  for_each = local.cb_sa_roles_expand
  project  = each.value.project_id
  role     = each.value.role
  member   = "serviceAccount:${local.cloudbuild_sa_email}"
}

resource "google_project_iam_member" "pool_user" {
  count = var.enable_worker_pool ? 1 : 0

  project = local.worker_pool_project
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:${data.google_project.cloudbuild_project[0].number}@cloudbuild.gserviceaccount.com"
}

# cross project impersonation if a custom CB SA is specified from a different project
resource "google_service_account_iam_member" "cb_sa_self" {
  for_each           = var.diff_sa_project ? toset(["roles/iam.serviceAccountUser", "roles/iam.serviceAccountTokenCreator"]) : []
  service_account_id = local.cloudbuild_sa
  role               = each.value
  member             = "serviceAccount:${local.cloudbuild_sa_email}"
}

data "google_project" "cloudbuild_project" {
  count      = var.diff_sa_project ? 1 : 0
  project_id = var.project_id
}

resource "google_service_account_iam_member" "cb_service_agent_impersonate" {
  count              = var.diff_sa_project ? 1 : 0
  service_account_id = local.cloudbuild_sa
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.cloudbuild_project[0].number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# allow CB SA to view source code if csr
resource "google_sourcerepo_repository_iam_member" "member" {
  count      = local.is_source_repo ? 1 : 0
  project    = local.source_repo_project
  repository = local.source_repo_name
  role       = "roles/viewer"
  member     = "serviceAccount:${local.cloudbuild_sa_email}"
}
