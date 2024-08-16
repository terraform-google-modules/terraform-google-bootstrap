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
  description = "Object structure to pass credential, only one type of credential must be passed. Supported types are GITHUBv2 and GITLABv2"
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
    condition = (
      var.credential_config.credential_type == "GITHUBv2" ? (
        var.credential_config.github_pat != null &&
        var.credential_config.github_app_id != null &&
        var.credential_config.gitlab_read_authorizer_credential == null &&
        var.credential_config.gitlab_authorizer_credential == null
        ) : var.credential_config.credential_type == "GITLABv2" ? (
        var.credential_config.github_pat == null &&
        var.credential_config.github_app_id == null &&
        var.credential_config.gitlab_read_authorizer_credential != null &&
        var.credential_config.gitlab_authorizer_credential != null
      ) : false
    )
    error_message = "You must specify a valid credential_type ('GITHUBv2' or 'GITLABv2'). For 'GITHUBv2', all 'github_' prefixed variables must be defined and no 'gitlab_' prefixed variables should be defined. For 'GITLABv2', all 'gitlab_' prefixed variables must be defined and no 'github_' prefixed variables should be defined."
  }
}

variable "cloudbuild_repos" {
  description = "Object structure to bring your own repositories."
  type = map(object({
    repo_name = string,
    repo_url  = string,
  }))

  validation {
    condition     = alltrue([for k, v in var.cloudbuild_repos : try(length(regex("^https://.*\\.git$", v.repo_url)) > 0, false)])
    error_message = "Each repo_url must be a valid HTTPS git clone URL ending with '.git'."
  }

}

variable "default_region" {
  description = "Default resources location"
  type        = string
  default     = "us-central1"
}

variable "cloudbuild_connection_name" {
  description = "Cloudbuild Connection Name"
  type        = string
  default     = "generic-cloudbuild-connection"
}
