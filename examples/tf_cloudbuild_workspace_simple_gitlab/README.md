## Github Requirements for Cloud Build Connection

When using a Cloud Build 2nd generation repository, a Cloud Build connection to your repository provider will be needed.
For GitLab connections you will need:

- To create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) on GitLab with `api` and `read_api` scopes.

For more information on this topic refer to the [Connect to a GitLab host](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-host-gitlab) and [Connect to a GitLab repository](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-repo-gitlab) documentation

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudbuildv2\_repository\_id | Cloudbuild 2nd gen repository ID. Format: 'projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}'. Must be defined if repository type is `CLOUDBUILD_V2_REPOSITORY`. | `string` | n/a | yes |
| gitlab\_pat | GitLab access token. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the repo where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifacts\_bucket | Bucket for storing TF plans |
| cloudbuild\_apply\_trigger\_id | Trigger used for running TF apply |
| cloudbuild\_plan\_trigger\_id | Trigger used for running TF plan |
| cloudbuild\_sa | SA used by Cloud Build triggers |
| logs\_bucket | Bucket for storing TF logs |
| project\_id | n/a |
| state\_bucket | Bucket for storing TF state |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
