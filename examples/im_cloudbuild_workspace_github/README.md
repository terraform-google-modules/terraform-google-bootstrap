<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| github\_pat\_secret | Secret that contains a GitHub personal access token. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_apply\_trigger\_id | TRigger used for running IM apply |
| cloudbuild\_preview\_trigger\_id | Trigger used for creating IM previews |
| project\_id | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
