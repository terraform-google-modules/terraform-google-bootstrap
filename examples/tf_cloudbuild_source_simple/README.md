## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_source](../../modules/tf_cloudbuild_source/) module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| parent\_folder | The bootstrap parent folder | `string` | `""` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id | Project where CloudBuild configuration and terraform container image will reside. |
| csr\_repos | List of Cloud Source Repos created by the module. |
| gcs\_cloudbuild\_default\_bucket | Bucket used to store temporary files in CloudBuild project. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
