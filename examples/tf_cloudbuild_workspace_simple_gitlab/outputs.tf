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

output "cloudbuild_plan_trigger_id" {
  description = "Trigger used for running TF plan"
  value       = module.tf_workspace.cloudbuild_plan_trigger_id
}

output "cloudbuild_apply_trigger_id" {
  description = "Trigger used for running TF apply"
  value       = module.tf_workspace.cloudbuild_apply_trigger_id
}

output "cloudbuild_sa" {
  description = "SA used by Cloud Build triggers"
  value       = module.tf_workspace.cloudbuild_sa
}

output "state_bucket" {
  description = "Bucket for storing TF state"
  value       = module.tf_workspace.state_bucket
}

output "logs_bucket" {
  description = "Bucket for storing TF logs"
  value       = module.tf_workspace.logs_bucket
}

output "artifacts_bucket" {
  description = "Bucket for storing TF plans"
  value       = module.tf_workspace.artifacts_bucket
}

output "project_id" {
  description = "The ID of the project in which the resources were provisioned"
  value       = var.project_id
}

output "location" {
  description = "The location in which the resources were provisioned"
  value       = local.location
}
