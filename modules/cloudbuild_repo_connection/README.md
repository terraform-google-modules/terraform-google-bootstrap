# Overview

This module is designed to create and manage secret versions, as well as configure the necessary permissions for cloud build service agent when utilizing Cloud Build repositories (2nd generation).

Additionally, it will establish the corresponding Cloud Build repositories based on the `cloudbuild_repos` variable, where users can specify the repository names and URLs from their version control systems.

Users will provide the required secrets through the `credential_config` variable, indicating their chosen Git provider. Currently, the module supports both GitHub and GitLab.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudbuild\_connection\_name | Cloudbuild Connection Name | `string` | `"generic-cloudbuild-connection"` | no |
| cloudbuild\_repos | Object structure to bring your own repositories. | <pre>map(object({<br>    repo_name = string,<br>    repo_url  = string,<br>  }))</pre> | n/a | yes |
| credential\_config | Object structure to pass credential, only one type of credential must be passed. Supported types are GITHUBv2 and GITLABv2 | <pre>object({<br>    credential_type                             = string<br>    github_secret_id                            = optional(string, "cb-github-pat")<br>    github_pat                                  = optional(string)<br>    github_app_id                               = optional(string)<br>    gitlab_read_authorizer_credential           = optional(string)<br>    gitlab_read_authorizer_credential_secret_id = optional(string, "cb-gitlab-read-api-credential")<br>    gitlab_authorizer_credential                = optional(string)<br>    gitlab_authorizer_credential_secret_id      = optional(string, "cb-gitlab-api-credential")<br>  })</pre> | n/a | yes |
| default\_region | Default resources location | `string` | `"us-central1"` | no |
| project\_id | The project id to create the secret and assign cloudbuild service account permissions. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_2nd\_gen\_connection | Cloudbuild connection created. |
| cloudbuild\_2nd\_gen\_repositories | Created repositories. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

