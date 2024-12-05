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

variable "connection_config" {
  description = <<-EOT
  Connection configuration options:
    - connection_type: Specifies the type of connection being used. Supported types are 'GITHUBv2' and 'GITLABv2'.
    - github_secret_id: (Optional) The secret ID for GitHub credentials.
    - github_app_id_secret_id: (Optional) The secret ID for the application ID for a GitHub App used for authentication. For app installation, follow this link: https://github.com/apps/google-cloud-build
    - gitlab_read_authorizer_credential_secret_id: (Optional) The secret ID for the GitLab read authorizer credential.
    - gitlab_authorizer_credential_secret_id: (Optional) The secret ID for the GitLab authorizer credential.
    - gitlab_webhook_secret_id: (Optional) The secret ID for the GitLab WebHook.
    - gitlab_enterprise_host_uri: (Optional) The URI of the GitLab Enterprise host this connection is for. If not specified, the default value is https://gitlab.com.
    - gitlab_enterprise_service_directory: (Optional) Configuration for using Service Directory to privately connect to a GitLab Enterprise server. This should only be set if the GitLab Enterprise server is hosted on-premises and not reachable by public internet. If this field is left empty, calls to the GitLab Enterprise server will be made over the public internet. Format: projects/{project}/locations/{location}/namespaces/{namespace}/services/{service}.
    - gitlab_enterprise_ca_certificate: (Optional) SSL certificate to use for requests to GitLab Enterprise.
  EOT
  type = object({
    connection_type                             = string
    github_secret_id                            = optional(string)
    github_app_id_secret_id                     = optional(string)
    gitlab_read_authorizer_credential_secret_id = optional(string)
    gitlab_authorizer_credential_secret_id      = optional(string)
    gitlab_webhook_secret_id                    = optional(string)
    gitlab_enterprise_host_uri                  = optional(string)
    gitlab_enterprise_service_directory         = optional(string)
    gitlab_enterprise_ca_certificate            = optional(string)
  })

  validation {
    condition     = var.connection_config.connection_type == "GITLABv2" || var.connection_config.connection_type == "GITHUBv2"
    error_message = "Specify one of the valid connection_types: 'GITLABv2' or 'GITHUBv2'."
  }

  validation {
    condition = var.connection_config.connection_type == "GITLABv2" ? (
      var.connection_config.gitlab_read_authorizer_credential_secret_id != null &&
      var.connection_config.gitlab_authorizer_credential_secret_id != null &&
      var.connection_config.gitlab_webhook_secret_id != null
    ) : true

    error_message = "For 'GITLABv2', 'gitlab_read_authorizer_credential_secret_id', 'gitlab_authorizer_credential_secret_id', and 'gitlab_webhook_secret_id' must be defined."
  }

  validation {
    condition = var.connection_config.connection_type == "GITHUBv2" ? (
      var.connection_config.github_secret_id != null &&
      var.connection_config.github_app_id_secret_id != null
    ) : true

    error_message = "For 'GITHUBv2', 'github_secret_id' and 'github_app_id_secret_id' must be defined."
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
