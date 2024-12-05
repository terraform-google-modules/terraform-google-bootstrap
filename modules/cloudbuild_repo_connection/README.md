# Overview

This module is designed to establish the corresponding Cloud Build repositories (2nd gen) based on the `cloud_build_repositories` variable, where users can specify the repository names and URLs from their own version control systems.

Additionally, it will configure the necessary permissions for cloud build service agent when utilizing Cloud Build repositories (2nd gen).

Users will provide the required secrets through the `connection_config` variable, indicating their chosen Git provider. Currently, the module supports both GitHub and GitLab.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud\_build\_repositories | Cloud Build repositories configuration:<br>  - repository\_name: The name of the repository to be used in Cloud Build.<br>  - repository\_url: The HTTPS clone URL for the repository. This URL must end with '.git' and be a valid HTTPS URL.<br><br>Each entry in this map must contain both `repository_name` and `repository_url` to properly integrate with the Cloud Build service. | <pre>map(object({<br>    repository_name = string,<br>    repository_url  = string,<br>  }))</pre> | n/a | yes |
| cloudbuild\_connection\_name | Cloudbuild Connection Name. | `string` | `"generic-cloudbuild-connection"` | no |
| connection\_config | Connection configuration options:<br>  - connection\_type: Specifies the type of connection being used. Supported types are 'GITHUBv2' and 'GITLABv2'.<br>  - github\_secret\_id: (Optional) The secret ID for GitHub credentials.<br>  - github\_app\_id\_secret\_id: (Optional) The secret ID for the application ID for a GitHub App used for authentication. For app installation, follow this link: https://github.com/apps/google-cloud-build<br>  - gitlab\_read\_authorizer\_credential\_secret\_id: (Optional) The secret ID for the GitLab read authorizer credential.<br>  - gitlab\_authorizer\_credential\_secret\_id: (Optional) The secret ID for the GitLab authorizer credential.<br>  - gitlab\_webhook\_secret\_id: (Optional) The secret ID for the GitLab WebHook.<br>  - gitlab\_enterprise\_host\_uri: (Optional) The URI of the GitLab Enterprise host this connection is for. If not specified, the default value is https://gitlab.com.<br>  - gitlab\_enterprise\_service\_directory: (Optional) Configuration for using Service Directory to privately connect to a GitLab Enterprise server. This should only be set if the GitLab Enterprise server is hosted on-premises and not reachable by public internet. If this field is left empty, calls to the GitLab Enterprise server will be made over the public internet. Format: projects/{project}/locations/{location}/namespaces/{namespace}/services/{service}.<br>  - gitlab\_enterprise\_ca\_certificate: (Optional) SSL certificate to use for requests to GitLab Enterprise. | <pre>object({<br>    connection_type                             = string<br>    github_secret_id                            = optional(string)<br>    github_app_id_secret_id                     = optional(string)<br>    gitlab_read_authorizer_credential_secret_id = optional(string)<br>    gitlab_authorizer_credential_secret_id      = optional(string)<br>    gitlab_webhook_secret_id                    = optional(string)<br>    gitlab_enterprise_host_uri                  = optional(string)<br>    gitlab_enterprise_service_directory         = optional(string)<br>    gitlab_enterprise_ca_certificate            = optional(string)<br>  })</pre> | n/a | yes |
| location | Resources location. | `string` | `"us-central1"` | no |
| project\_id | The project id to create the secret and assign cloudbuild service account permissions. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_build\_repositories\_2nd\_gen\_connection | The unique identifier of the Cloud Build connection created within the specified Google Cloud project.<br>  Example format: projects/{{project}}/locations/{{location}}/connections/{{name}} |
| cloud\_build\_repositories\_2nd\_gen\_repositories | A map of created repositories associated with the Cloud Build connection.<br>Each entry contains the repository's unique identifier and its remote URL.<br>Example format:<br>"key\_name" = {<br>  "id" =  "projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}",<br>  "url" = "https://github.com/{{account/org}}/{{repository_name}}.git"<br>} |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
