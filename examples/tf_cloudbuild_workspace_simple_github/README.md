<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudbuildv2\_repository\_id | Cloudbuild 2nd gen repository ID. Format: 'projects/{{project}}/locations/{{location}}/connections/{{parent\_connection}}/repositories/{{name}}'. Must be defined if repository type is `CLOUDBUILD_V2_REPOSITORY`. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |

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
