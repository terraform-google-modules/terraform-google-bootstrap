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

variable "deployment_id" {
  description = "Custom ID to be used for the Infrastructure Manager deployment."
  type = string
}

variable "service_account" {
  description = "Service account used to call Infrastructure Manager."
  type = string
}

variable "github_app_installation_id" {
  description = "Installation ID of the GitHub Cloud Build application."
  type = string
}

variable "repo_pat" {
  description = "Personal access token for a repository."
  type = string
  sensitive = true
}

variable "input_variables" {
  description = "Input variables to pass to Infrastructure Manager."
  type = string
  default = null
}

variable "cb_tf_builder_version" {
  description = "Cloud Builder image version. Defaults to the latest."
  type = string
  default = null
}

variable "is_github_repo" {
  description = "Flag indicating we're using a GitHub repository."
  type = bool
  default = true
}

variable "is_gitlab_repo" {
  description = "Flag indicating we're using a GitLab repository."
  type = bool
  default = false 
}

variable "im_repo_uri" {
  description = "Repository URI for the Terraform configs."
  type = string
}