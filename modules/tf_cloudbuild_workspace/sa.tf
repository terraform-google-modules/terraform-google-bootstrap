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
  # extract email/project from CB SA id form projects/{{project}}/serviceAccounts/{{email}}
  cloudbuild_sa         = var.cloudbuild_sa != "" ? var.cloudbuild_sa : google_service_account.cb_sa[0].id
  cloudbuild_sa_email   = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 1)
  cloudbuild_sa_project = element(split("/", local.cloudbuild_sa), length(split("/", local.cloudbuild_sa)) - 3)
  # check if given service account is from a different project as additional setup needed
  # https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#cross-project_set_up
  diff_sa_project = try(google_service_account.cb_sa[0].project, local.cloudbuild_sa_project) != var.project_id

  # Optional roles for CB SA
  cb_sa_roles_expand = distinct(flatten([for project, roles in var.cloudbuild_sa_roles : [for role in roles : { project = project, role = role }]]))
  # https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
  cb_sa_roles_with_log = toset(concat(local.cb_sa_roles_expand, [{ project = var.project_id, role = "roles/logging.logWriter" }]))
}


resource "google_service_account" "cb_sa" {
  count        = var.cloudbuild_sa == "" ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cb-${local.default_prefix}"
  display_name = "SA for Terraform build trigger ${local.default_prefix}. Managed by Terraform."
}

# https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts#permissions
resource "google_project_iam_member" "cb_sa_roles" {
  for_each = { for pr in local.cb_sa_roles_with_log : "${pr.project}/${pr.role}" => pr }
  project  = each.value.project
  role     = each.value.role
  member   = "serviceAccount:${local.cloudbuild_sa_email}"
}

# cross project impersonation if a custom CB SA is specified from a different project
resource "google_service_account_iam_member" "cb_sa_self" {
  for_each           = local.diff_sa_project ? toset(["roles/iam.serviceAccountUser", "roles/iam.serviceAccountTokenCreator"]) : []
  service_account_id = local.cloudbuild_sa
  role               = each.value
  member             = "serviceAccount:${local.cloudbuild_sa_email}"
}

data "google_project" "cloudbuild_project" {
  count      = local.diff_sa_project ? 1 : 0
  project_id = var.project_id
}

resource "google_service_account_iam_member" "cb_service_agent_impersonate" {
  count              = local.diff_sa_project ? 1 : 0
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
