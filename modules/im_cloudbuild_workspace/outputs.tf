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

output "cloudbuild_preview_trigger_id" {
  description = "Trigger used for running infra-manager preview"
  value       = google_cloudbuild_trigger.triggers["preview"].id
}

output "cloudbuild_apply_trigger_id" {
  description = "Trigger used for running infra-manager apply"
  value       = google_cloudbuild_trigger.triggers["apply"].id
}

output "cloudbuild_sa" {
  description = "Service account used by the Cloud Build triggers"
  value       = local.cloudbuild_sa
}

output "infra_manager_sa" {
  description = "Service account used by Infrastructure Manager"
  value       = local.im_sa
}

output "vcs_connection_id" {
  description = "The Cloud Build VCS host connection ID"
  value       = google_cloudbuildv2_connection.vcs_connection.id
}

output "repo_connection_id" {
  description = "The Cloud Build repository connection ID"
  value       = google_cloudbuildv2_repository.repository_connection.id
}

output "github_secret_id" {
  description = "The secret ID for the GitHub secret containing the personal access token."
  value       = local.github_secret_id
  sensitive   = true
}

output "gitlab_api_secret_id" {
  description = "The secret ID for the GitLab secret containing the token with api access."
  value       = local.api_secret_id
  sensitive   = true
}

output "gitlab_read_api_secret_id" {
  description = "The secret ID for the GitLab secret containing the token with read_api access."
  value       = local.read_api_secret_id
  sensitive   = true
}
