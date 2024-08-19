# Overview

This module is designed to establish the corresponding Cloud Build repositories (2nd gen) based on the `cloud_build_repositories` variable, where users can specify the repository names and URLs from their own version control systems.

Additionally, it will create and manage secret versions, as well as configure the necessary permissions for cloud build service agent when utilizing Cloud Build repositories (2nd gen).

Users will provide the required secrets through the `credential_config` variable, indicating their chosen Git provider. Currently, the module supports both GitHub and GitLab.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud\_build\_repositories | Cloud Build repositories configuration:<br>  - repository\_name: The name of the repository to be used in Cloud Build.<br>  - repository\_url: The HTTPS clone URL for the repository. This URL must end with '.git' and be a valid HTTPS URL.<br><br>Each entry in this map must contain both `repository_name` and `repository_url` to properly integrate with the Cloud Build service. | <pre>map(object({<br>    repository_name = string,<br>    repository_url  = string,<br>  }))</pre> | n/a | yes |
| cloudbuild\_connection\_name | Cloudbuild Connection Name. | `string` | `"generic-cloudbuild-connection"` | no |
| credential\_config | Credential configuration options:<br>  - credential\_type: Specifies the type of credential being used. Supported types are 'GITHUBv2' and 'GITLABv2'.<br>  - github\_secret\_id: (Optional) The secret ID for GitHub credentials. Default is "cb-github-pat".<br>  - github\_pat: (Optional) The personal access token for GitHub authentication.<br>  - github\_app\_id: (Optional) The application ID for a GitHub App used for authentication. For app installation, follow this link: https://github.com/apps/google-cloud-build<br>  - gitlab\_read\_authorizer\_credential: (Optional) The read authorizer credential for GitLab access.<br>  - gitlab\_read\_authorizer\_credential\_secret\_id: (Optional) The secret ID for the GitLab read authorizer credential. Default is "cb-gitlab-read-api-credential".<br>  - gitlab\_authorizer\_credential: (Optional) The authorizer credential for GitLab access.<br>  - gitlab\_authorizer\_credential\_secret\_id: (Optional) The secret ID for the GitLab authorizer credential. Default is "cb-gitlab-api-credential". | <pre>object({<br>    credential_type                             = string<br>    github_secret_id                            = optional(string, "cb-github-pat")<br>    github_pat                                  = optional(string)<br>    github_app_id                               = optional(string)<br>    gitlab_read_authorizer_credential           = optional(string)<br>    gitlab_read_authorizer_credential_secret_id = optional(string, "cb-gitlab-read-api-credential")<br>    gitlab_authorizer_credential                = optional(string)<br>    gitlab_authorizer_credential_secret_id      = optional(string, "cb-gitlab-api-credential")<br>  })</pre> | n/a | yes |
| location | Resources location. | `string` | `"us-central1"` | no |
| project\_id | The project id to create the secret and assign cloudbuild service account permissions. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_build\_repositories\_2nd\_gen\_connection | The unique identifier of the Cloud Build connection created within the specified Google Cloud project.<br>  Example format: projects/{{project}}/locations/{{location}}/connections/{{name}} |
| cloud\_build\_repositories\_2nd\_gen\_repositories | A map of created repositories associated with the Cloud Build connection.<br>Each entry contains the repository's unique identifier and its remote URL.<br>Example format:<br>"key\_name" = {<br>  "id" =  "projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}",<br>  "url" = "https://github.com/{{account/org}}/{{repository_name}}.git"<br>} |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
