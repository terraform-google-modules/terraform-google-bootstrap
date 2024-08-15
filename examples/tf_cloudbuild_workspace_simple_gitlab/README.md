## Github Requirements for Cloud Build Connection

When using a Cloud Build repositories (2nd gen) GitLab repository, a Cloud Build connection to your repository provider will be needed.

For more information on this topic refer to the Cloud Build repositories (2nd gen) documentation:
- [Connect to a GitLab host](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-host-gitlab)
- [Connect to a GitLab repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gitlab\_api\_access\_token | GitLab personal access token with api scope. If provided, creates a secret within Secret Manager. | `string` | n/a | yes |
| gitlab\_read\_api\_access\_token | GitLab personal access token with read\_api scope. If provided, creates a secret within Secret Manager. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the GitLab repository where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifacts\_bucket | Bucket for storing TF plans |
| cloudbuild\_apply\_trigger\_id | Trigger used for running TF apply |
| cloudbuild\_plan\_trigger\_id | Trigger used for running TF plan |
| cloudbuild\_sa | SA used by Cloud Build triggers |
| location | The location in which the resources were provisioned |
| logs\_bucket | Bucket for storing TF logs |
| project\_id | The ID of the project in which the resources were provisioned |
| state\_bucket | Bucket for storing TF state |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
