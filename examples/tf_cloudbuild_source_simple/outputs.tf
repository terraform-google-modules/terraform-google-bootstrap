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

output "cloudbuild_project_id" {
  description = "Project where CloudBuild configuration and terraform container image will reside."
  value       = module.tf_source.cloudbuild_project_id
}

output "csr_repos" {
  description = "List of Cloud Source Repos created by the module."
  value       = module.tf_source.csr_repos
}

output "gcs_cloudbuild_default_bucket" {
  description = "Bucket used to store temporary files in CloudBuild project."
  value       = module.tf_source.gcs_cloudbuild_default_bucket
}
