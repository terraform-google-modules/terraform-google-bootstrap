## Overview

This example demonstrates the simplest usage of the [im_cloudbuild_workspace](../../modules/im_cloudbuild_workspace/) module.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deployment\_id | Custom ID to be used for the Infrastructure Manager deployment. | `string` | n/a | yes |
| github\_app\_installation\_id | Installation ID of the GitHub Cloud Build application. | `string` | `""` | no |
| github\_repo\_pat | Personal access token for GitHub. | `string` | `""` | no |
| gitlab\_api\_token | GitLab PAT with api access. | `string` | `""` | no |
| gitlab\_read\_api\_token | GitLab PAT with read\_api access. | `string` | `""` | no |
| im\_repo\_directory | Optional subdirectory within the repository. | `string` | `""` | no |
| im\_repo\_ref | Git reference of the configuration. Will use the repository's default branch if not specified. | `string` | `""` | no |
| im\_repo\_uri | URI of the repository where the triggers will be connected to. | `string` | n/a | yes |
| input\_variables | Input variables to pass to Infrastructure Manager. | `string` | `""` | no |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| tf\_repo\_type | Type of repo | `string` | `"GITHUB"` | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->