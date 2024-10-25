## Overview

This example combines the Organization bootstrap module with the Cloud Build submodule, to setup everything that is required to run subsequent infrastructure as code using cloud native tooling and limited external dependencies. For more details on what the Cloud Build module is doing, see the [readme](../../modules/cloudbuild).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| force\_destroy | If supplied, the logs and artifacts buckets will be deleted even while containing objects. | `bool` | `false` | no |
| group\_billing\_admins | Google Group for GCP Billing Administrators | `string` | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| org\_project\_creators | Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required. | `list(string)` | `[]` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |
| project\_prefix | Name prefix to use for projects created. | `string` | `"cft"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id | Project where CloudBuild configuration and terraform container image will reside. |
| csr\_repos | List of Cloud Source Repos created by the module, linked to Cloud Build triggers. |
| gcs\_bucket\_cloudbuild\_artifacts | Bucket used to store Cloud/Build artifacts in CloudBuild project. |
| gcs\_bucket\_cloudbuild\_logs | Bucket used to store Cloud/Build logs in CloudBuild project. |
| gcs\_bucket\_tfstate | Bucket used for storing terraform state for foundations pipelines in seed project. |
| seed\_project\_id | Project where service accounts and core APIs will be enabled. |
| terraform\_sa\_email | Email for privileged service account for Terraform. |
| terraform\_sa\_name | Fully qualified name for privileged service account for Terraform. |
| tf\_runner\_artifact\_repo | GAR Repo created to store runner images |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
