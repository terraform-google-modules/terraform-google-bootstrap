<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| billing\_account | The ID of the billing account to associate projects with. | string | n/a | yes |
| default\_region | Default region to create resources where applicable. | string | n/a | yes |
| group\_billing\_admins | Google Group for GCP Billing Administrators | string | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | string | n/a | yes |
| organization\_id | GCP Organization ID | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id |  |
| csr\_repos |  |
| gcs\_bucket\_cloudbuild\_artifacts |  |
| gcs\_bucket\_tfstate |  |
| kms\_crypto\_key |  |
| kms\_keyring |  |
| seed\_project\_id |  |
| terraform\_sa\_email |  |
| terraform\_sa\_name |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->