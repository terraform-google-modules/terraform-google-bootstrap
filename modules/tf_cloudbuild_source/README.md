## Overview

## Usage

Basic usage of this module is as follows:

```hcl
module "tf-cloudbuild-core" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_source"
  version = "~> 11.0"

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
- Set of Cloud Source Repos.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | List of APIs to enable in the Cloudbuild project. | `list(string)` | <pre>[<br>  "serviceusage.googleapis.com",<br>  "servicenetworking.googleapis.com",<br>  "compute.googleapis.com",<br>  "logging.googleapis.com",<br>  "iam.googleapis.com",<br>  "admin.googleapis.com"<br>]</pre> | no |
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| buckets\_force\_destroy | When deleting CloudBuild buckets, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| cloud\_source\_repos | List of Cloud Source Repos to create with CloudBuild triggers. | `list(string)` | <pre>[<br>  "gcp-policies",<br>  "gcp-org",<br>  "gcp-envs",<br>  "gcp-networks",<br>  "gcp-projects"<br>]</pre> | no |
| folder\_id | The ID of a folder to host this project | `string` | `""` | no |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| location | Location for build artifacts bucket | `string` | `"us-central1"` | no |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| project\_auto\_create\_network | Create the default network for the project created. | `bool` | `false` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |
| project\_id | Custom project ID to use for project created. | `string` | `""` | no |
| project\_labels | Labels to apply to the project. | `map(string)` | `{}` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id | Project for CloudBuild and Cloud Source Repositories. |
| csr\_repos | List of Cloud Source Repos created by the module. |
| gcs\_cloudbuild\_default\_bucket | Bucket used to store temporary files in CloudBuild project. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- [terraform-provider-google] plugin >= 3.50.x

### Permissions

- `roles/resourcemanager.projectCreator`
- `roles/billing.user`

## Contributing

Refer to the [contribution guidelines](../../CONTRIBUTING.md) for
information on contributing to this module.
