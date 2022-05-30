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

output "artifact_repo" {
  description = "GAR Repo created to store TF Cloud Builder images"
  value       = google_artifact_registry_repository.tf-image-repo.name
}

output "workflow_id" {
  description = "Workflow ID for triggering new TF Builder build"
  value       = google_workflows_workflow.builder.id
}

output "workflow_sa" {
  description = "SA used by Workflow for triggering new TF Builder build"
  value       = local.workflow_sa
}

output "scheduler_id" {
  description = "Scheduler ID for periodically triggering TF Builder build Workflow"
  value       = google_cloud_scheduler_job.trigger_workflow.id
}

output "cloudbuild_trigger_id" {
  description = "Trigger used for building new TF Builder"
  value       = google_cloudbuild_trigger.build_trigger.id
}

output "cloudbuild_sa" {
  description = "SA used by Cloud Build trigger"
  value       = local.cloudbuild_sa
}
