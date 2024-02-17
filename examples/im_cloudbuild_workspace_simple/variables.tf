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
  description = "If provided, the service account used to call Infrastructure Manager. One will be created otherwise."
  type = string
  default = null
}

variable "input_variables" {
  description = "Input variables to pass to Infrastructure Manager."
  type = string
  default = null
}

variable "im_repo_uri" {
  description = "URI of the repository where the triggers will be connected to."
  type = string
}

variable "im_repo_directory" {
  description = "Optional subdirectory within the repository."
  type = string
  default = "" 
}

variable "im_repo_ref" {
  description = "Git reference of the configuration. Will use the repository's default branch if not specified."
  type = string
  default = "" 
}

variable "tf_repo_type" {
  description = "Type of repo"
  type        = string
  default = "GITHUB"
}

# GitHub specific variables
variable "repo_pat" {
  description = "Personal access token for a repository."
  type = string
  sensitive = true
}

variable "github_app_installation_id" {
  description = "Installation ID of the GitHub Cloud Build application."
  type = string
}

# GitLab specific variables
variable "gitlab_api_token" {
  type = string
  sensitive = true
  default = null
}

variable "gitlab_read_api_token" {
  type = string
  sensitive = true
  default = null
}