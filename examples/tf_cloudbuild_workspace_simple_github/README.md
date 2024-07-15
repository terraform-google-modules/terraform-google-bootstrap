## Github Requirements for Cloud Build Connection

When using a Cloud Build 2nd generation repository, a Cloud Build connection to your repository provider will be needed. For Github connections you will need:

- [Install Cloud Build App on Github](https://github.com/apps/google-cloud-build).
- [Create Personal Access Token on Github with `repo` and `read:user` (or if app is installed in org use `read:org`)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

For more information on this topic refer to the ["Connect with Github Documentation"](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudbuildv2\_repository\_id | Cloudbuild 2nd gen repository ID. Format: 'projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}'. Must be defined if repository type is `CLOUDBUILD_V2_REPOSITORY`. | `string` | n/a | yes |
| create\_cloudbuild\_sa | Create a Service Account for use in Cloud Build. If false `cloudbuild_sa` has to be specified. | `bool` | `true` | no |
| create\_cloudbuild\_sa\_name | Custom name to be used in the creation of the Cloud Build service account if `create_cloudbuild_sa` is true. Defaults to generated name if empty | `string` | `""` | no |
| github\_pat | GitHub personal access token. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the repo where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifacts\_bucket | Bucket for storing TF plans |
| cloudbuild\_apply\_trigger\_id | Trigger used for running TF apply |
| cloudbuild\_plan\_trigger\_id | Trigger used for running TF plan |
| cloudbuild\_sa | SA used by Cloud Build triggers |
| github\_repo\_id | CSR repo for storing TF configs |
| logs\_bucket | Bucket for storing TF logs |
| project\_id | n/a |
| state\_bucket | Bucket for storing TF state |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
