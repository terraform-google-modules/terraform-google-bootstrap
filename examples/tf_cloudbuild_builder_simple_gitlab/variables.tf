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

variable "gitlab_api_access_token" {
  description = "GitLab personal access token with api scope. If provided, creates a secret within Secret Manager."
  type        = string
  sensitive   = true
}

variable "gitlab_read_api_access_token" {
  description = "GitLab personal access token with read_api scope. If provided, creates a secret within Secret Manager."
  type        = string
  sensitive   = true
}

variable "repository_uri" {
  description = "The URI of the GitLab repository where the Terraform configs are stored."
  type        = string
}
