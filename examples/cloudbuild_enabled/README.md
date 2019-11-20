## Overview

This example combines the Organization bootstrap module with the Cloud Build submodule, to setup everything that is required to run subsequent infrastructure as code using cloud native tooling and limited external dependencies. For more details on what the Cloud Build module is doing, see the [readme](../../modules/cloudbuild).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account | The ID of the billing account to associate projects with. | string | n/a | yes |
| default\_region | Default region to create resources where applicable. | string | n/a | yes |
| group\_billing\_admins | Google Group for GCP Billing Administrators | string | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | string | n/a | yes |
| org\_id | GCP Organization ID | string | n/a | yes |
| org\_project\_creators | Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required. | list(string) | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id |  |
| csr\_repos |  |
| gcs\_bucket\_cloudbuild\_artifacts |  |
| gcs\_bucket\_tfstate |  |
| group\_billing\_admins |  |
| group\_org\_admins |  |
| kms\_crypto\_key |  |
| kms\_keyring |  |
| seed\_project\_id |  |
| terraform\_sa\_email |  |
| terraform\_sa\_name |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
