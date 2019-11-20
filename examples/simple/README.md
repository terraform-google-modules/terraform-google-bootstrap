## Overview

This example demonstrates the simplest usage of the GCP organization bootstrap module, accepting default values for the module variables.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account | The ID of the billing account to associate projects with. | string | n/a | yes |
| default\_region | Default region to create resources where applicable. | string | `"us-central1"` | no |
| group\_billing\_admins | Google Group for GCP Billing Administrators | string | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | string | n/a | yes |
| org\_id | GCP Organization ID | string | n/a | yes |
| org\_project\_creators | Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required. | list(string) | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| gcs\_bucket\_tfstate |  |
| seed\_project\_id |  |
| terraform\_sa\_email |  |
| terraform\_sa\_name |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
