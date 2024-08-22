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
  description = "The project id to create the secret and assign cloudbuild service account permissions."
  type        = string
}

variable "credential_config" {
  description = <<-EOT
  Credential configuration options:
    - credential_type: Specifies the type of credential being used. Supported types are 'GITHUBv2' and 'GITLABv2'.
    - github_secret_id: (Optional) The secret ID for GitHub credentials. Default is "cb-github-pat".
    - github_pat: (Optional) The personal access token for GitHub authentication.
    - github_app_id: (Optional) The application ID for a GitHub App used for authentication. For app installation, follow this link: https://github.com/apps/google-cloud-build
    - gitlab_read_authorizer_credential: (Optional) The read authorizer credential for GitLab access.
    - gitlab_read_authorizer_credential_secret_id: (Optional) The secret ID for the GitLab read authorizer credential. Default is "cb-gitlab-read-api-credential".
    - gitlab_authorizer_credential: (Optional) The authorizer credential for GitLab access.
    - gitlab_authorizer_credential_secret_id: (Optional) The secret ID for the GitLab authorizer credential. Default is "cb-gitlab-api-credential".
  EOT
  type = object({
    credential_type                             = string
    github_secret_id                            = optional(string, "cb-github-pat")
    github_pat                                  = optional(string)
    github_app_id                               = optional(string)
    gitlab_read_authorizer_credential           = optional(string)
    gitlab_read_authorizer_credential_secret_id = optional(string, "cb-gitlab-read-api-credential")
    gitlab_authorizer_credential                = optional(string)
    gitlab_authorizer_credential_secret_id      = optional(string, "cb-gitlab-api-credential")
  })

  validation {
    condition     = var.credential_config.credential_type == "GITLABv2" || var.credential_config.credential_type == "GITHUBv2"
    error_message = "Specify one of the valid credential_types: 'GITLABv2' or 'GITHUBv2'."
  }

  validation {
    condition = var.credential_config.credential_type == "GITLABv2" ? (
      var.credential_config.gitlab_read_authorizer_credential != null &&
      var.credential_config.gitlab_authorizer_credential != null
    ) : true

    error_message = "For 'GITLABv2', 'gitlab_read_authorizer_credential' and 'gitlab_authorizer_credential' must be defined."
  }

  validation {
    condition = var.credential_config.credential_type == "GITHUBv2" ? (
      var.credential_config.github_pat != null &&
      var.credential_config.github_app_id != null
    ) : true

    error_message = "For 'GITHUBv2', 'github_pat' and 'github_app_id' must be defined."
  }
}

variable "cloud_build_repositories" {
  description = <<-EOT
  Cloud Build repositories configuration:
    - repository_name: The name of the repository to be used in Cloud Build.
    - repository_url: The HTTPS clone URL for the repository. This URL must end with '.git' and be a valid HTTPS URL.

  Each entry in this map must contain both `repository_name` and `repository_url` to properly integrate with the Cloud Build service.
  EOT
  type = map(object({
    repository_name = string,
    repository_url  = string,
  }))

  validation {
    condition     = alltrue([for k, v in var.cloud_build_repositories : try(length(regex("^https://.*\\.git$", v.repository_url)) > 0, false)])
    error_message = "Each repository_url must be a valid HTTPS git clone URL ending with '.git'."
  }

}

variable "location" {
  description = "Resources location."
  type        = string
  default     = "us-central1"
}

variable "cloudbuild_connection_name" {
  description = "Cloudbuild Connection Name."
  type        = string
  default     = "generic-cloudbuild-connection"
}
