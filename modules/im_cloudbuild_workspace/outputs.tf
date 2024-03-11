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

output "location" {
  description = "Location for Infrastructure Manager deployment."
  value       = var.location
}

output "trigger_location" {
  description = "Location of for Cloud Build triggers created in the workspace. Matches `location` if not given."
  value       = var.trigger_location
}

output "im_deployment_repo_uri" {
  description = "The URI of the repo where the Terraform configs are stored and triggers are created for"
  value       = var.im_deployment_repo_uri
}

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
