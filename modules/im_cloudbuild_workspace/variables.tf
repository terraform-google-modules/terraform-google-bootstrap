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
  description = "GCP project for Infrastructure Manager deployments and Cloud Build triggers."
  type        = string
}

variable "location" {
  description = "Location for Infrastructure Manager deployment."
  type        = string
  default     = "us-central1"
}

variable "trigger_location" {
  description = "Location of for Cloud Build triggers created in the workspace. Matches `location` if not given."
  type        = string
  default     = "us-central1"
}

variable "deployment_id" {
  description = "Custom ID to be used for the Infrastructure Manager deployment."
  type        = string
}

variable "host_connection_name" {
  description = "Name for the VCS connection. Generated if not given."
  type        = string
  default     = ""
}

variable "repo_connection_name" {
  description = "Connection name for linked repository. Generated if not given."
  type        = string
  default     = ""
}

variable "cloudbuild_sa" {
  description = "Custom SA ID of form projects/{{project}}/serviceAccounts/{{email}} to be used for creating Cloud Build triggers. Creates one if not given."
  type        = string
  default     = ""
}

variable "custom_cloudbuild_sa_name" {
  description = "Custom name to be used if creating a Cloud Build service account. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "infra_manager_sa" {
  description = "Custom SA id of form projects/{{project}}/serviceAccounts/{{email}} to be used by Infra Manager. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "custom_infra_manager_sa_name" {
  description = "Custom name to be used if creating an Infrastructure Manager service account. Defaults to generated name if empty."
  type        = string
  default     = ""
}

variable "infra_manager_sa_roles" {
  description = "List of roles to grant to Infrastructure Manager SA for actuating resources defined in the Terraform configuration."
  type        = list(string)
  default     = []
}

variable "im_deployment_repo_uri" {
  description = "The URI of the repo where the Terraform configs are stored."
  type        = string
}

variable "im_deployment_repo_dir" {
  description = "The directory inside the repo where the Terraform root config is located. If empty defaults to repo root."
  type        = string
  default     = ""
}

variable "im_deployment_ref" {
  description = "Git branch or ref configured to run infra-manager apply. All other refs will run plan by default."
  type        = string
}

variable "im_tf_variables" {
  description = "Optional list of Terraform variables to pass to Infrastructure Manager, if the configuration exists in a different repo. List of strings of form KEY=VALUE expected."
  type        = string
  default     = ""
}

variable "cloudbuild_preview_filename" {
  description = "Optional Cloud Build YAML definition used for Cloud Build triggers of Infra Manager preview. Defaults to using inline definition."
  type        = string
  default     = ""
}

variable "cloudbuild_apply_filename" {
  description = "Optional Cloud Build YAML definition used for Cloud Build triggers of Infra Manager apply. Defaults to using inline definition."
  type        = string
  default     = ""
}

variable "substitutions" {
  description = "Optional map of substitutions to use in builds if using a custom Cloud Build YAML definition."
  type        = map(string)
  default     = {}
}

variable "cloudbuild_included_files" {
  description = "Optional list. Changes affecting at least one of these files will invoke a build."
  type        = list(string)
  default     = []
}

variable "cloudbuild_ignored_files" {
  description = "Optional list. Changes only affecting ignored files will not invoke a build."
  type        = list(string)
  default     = []
}

variable "tf_version" {
  description = "Terraform version to use for Infrastructure Manager and the Cloud Builder image."
  type        = string
  default     = "1.2.3"
}

variable "tf_cloudbuilder" {
  description = "Name of the Cloud Builder image used for running build steps."
  type        = string
  default     = "hashicorp/terraform"
}

variable "tf_repo_type" {
  description = "Type of repo"
  type        = string
  default     = "GITHUB"
  validation {
    condition     = contains(["GITHUB", "GITLAB"], var.tf_repo_type)
    error_message = "Must be one of GITHUB or GITLAB"
  }
}

variable "pull_request_comment_control" {
  description = "Configure builds to run whether a repository owner or collaborator needs to comment /gcbrun."
  type        = string
  default     = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
  validation {
    condition     = contains(["COMMENTS_DISABLED", "COMMENTS_ENABLED", "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"], var.pull_request_comment_control)
    error_message = "Must be one of COMMENTS_DISABLED, COMMENTS_ENABLED, or COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
  }
}

# GitHub specific variables

variable "github_app_installation_id" {
  description = "Installation ID of the Cloud Build GitHub app used for pull and push request triggers."
  type        = string
  default     = ""
}

variable "github_personal_access_token" {
  description = "Personal access token for a GitHub repository. If provided, creates a secret within Secret Manager."
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_pat_secret" {
  description = "The secret ID within Secret Manager for an existing personal access token for GitHub."
  type        = string
  default     = ""
}

variable "github_pat_secret_version" {
  description = "The secret version ID or alias for the GitHub PAT secret. Uses the latest if not provided."
  type        = string
  default     = ""
}

# GitLab specific variables

variable "gitlab_host_uri" {
  description = "The URI of the GitLab Enterprise host this connection is for. Defaults to non-enterprise."
  type        = string
  default     = ""
}

variable "gitlab_api_access_token" {
  description = "GitLab personal access token with api scope. If provided, creates a secret within Secret Manager."
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_api_access_token_secret" {
  description = "The secret ID within Secret Manager for an existing api access token for GitLab."
  type        = string
  default     = ""
}

variable "gitlab_api_access_token_secret_version" {
  description = "The secret version ID or alias for the GitLab api token secret. Uses the latest if not provided."
  type        = string
  default     = ""
}

variable "gitlab_read_api_access_token" {
  description = "GitLab personal access token with read_api scope. If provided, creates a secret within Secret Manager."
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_read_api_access_token_secret" {
  description = "The secret ID within Secret Manager for an existing read_api access token for GitLab."
  type        = string
  default     = ""
}

variable "gitlab_read_api_access_token_secret_version" {
  description = "The secret version ID or alias for the GitLab read_api token secret. Uses the latest if not provided."
  type        = string
  default     = ""
}
