## Overview

## Usage

Basic usage of this module is as follows:

```hcl
module "tf-cloudbuild-core" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_core"
  version = "~> 6.1"

  org_id           = var.org_id
  billing_account  = var.billing_account
  group_org_admins = var.group_org_admins
}
```

Functional examples are included in the [examples](../../examples/) directory.

## Resources created

This module creates:

- Project for Cloud Build.
- Default Cloud Build bucket.
- Bucket for Cloud Build artifacts.
- Set of Cloud Source Repos.
- Optional [private pool](https://cloud.google.com/build/docs/private-pools/private-pools-overview).
- Optional Organization policy for [enforcing the usage of private pool](https://cloud.google.com/build/docs/private-pools/use-in-private-network#enforcing_the_usage_of_private_pools).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | List of APIs to enable in the Cloudbuild project. | `list(string)` | <pre>[<br>  "serviceusage.googleapis.com",<br>  "servicenetworking.googleapis.com",<br>  "compute.googleapis.com",<br>  "logging.googleapis.com",<br>  "bigquery.googleapis.com",<br>  "cloudresourcemanager.googleapis.com",<br>  "cloudbilling.googleapis.com",<br>  "iam.googleapis.com",<br>  "admin.googleapis.com",<br>  "appengine.googleapis.com",<br>  "storage-api.googleapis.com"<br>]</pre> | no |
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| buckets\_force\_destroy | When deleting CloudBuild buckets, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| cloud\_source\_repos | List of Cloud Source Repos to create with CloudBuild triggers. | `list(string)` | <pre>[<br>  "gcp-policies",<br>  "gcp-org",<br>  "gcp-envs",<br>  "gcp-networks",<br>  "gcp-projects"<br>]</pre> | no |
| create\_cloud\_source\_repos | If shared Cloud Source Repos should be created. | `bool` | `true` | no |
| folder\_id | The ID of a folder to host this project | `string` | `""` | no |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| location | Location for build artifacts bucket | `string` | `"us-central1"` | no |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| project\_id | Custom project ID to use for project created. | `string` | `""` | no |
| project\_labels | Labels to apply to the project. | `map(string)` | `{}` | no |
| project\_prefix | Name prefix to use for projects created. | `string` | `"cft"` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| use\_random\_suffix | Appends a 4 character random suffix to project ID. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id | Project where CloudBuild configuration and terraform container image will reside. |
| csr\_repos | List of Cloud Source Repos created by the module. |
| gcs\_bucket\_cloudbuild\_artifacts | Bucket used to store Cloud/Build artifacts in CloudBuild project. |
| gcs\_cloudbuild\_default\_bucket | Bucket used to store temporary files in CloudBuild project. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

- [Terraform](https://www.terraform.io/downloads.html) >= 0.13.0
- [terraform-provider-google] plugin >= 3.50.x

### Permissions

- `roles/resourcemanager.projectCreator`
- `roles/billing.user`

## Contributing

Refer to the [contribution guidelines](../../CONTRIBUTING.md) for
information on contributing to this module.
