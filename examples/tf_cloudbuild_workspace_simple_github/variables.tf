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

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "cloudbuildv2_repository_id" {
  description = "Cloudbuild 2nd gen repository ID. Format: 'projects/{{project}}/locations/{{location}}/connections/{{parent_connection}}/repositories/{{name}}'. Must be defined if repository type is `CLOUDBUILD_V2_REPOSITORY`."
  type        = string
}

variable "github_pat" {
  description = "GitHub personal access token."
  type        = string
  sensitive   = true
}

variable "repository_uri" {
  description = "The URI of the repo where the Terraform configs are stored."
  type        = string
}
