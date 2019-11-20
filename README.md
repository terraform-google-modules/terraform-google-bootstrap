# terraform-google-bootstrap

The purpose of this module is to help bootstrap a GCP organization, creating all the required GCP resources & permissions to start using the Cloud Foundation Toolkit (CFT). For users who want to use Cloud Build & Cloud Source Repos for foundations code, there is also a submodule to help bootstrap all the required resources to do this.

## Usage

Basic usage of this module is as follows:

```hcl
module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
  version = "~> 0.1"

  org_id      = "<ORGANIZATION_ID>"
  billing_account      = "<BILLING_ACCOUNT_ID>"
  group_org_admins     = "gcp-organization-admins@example.com"
  group_billing_admins = "gcp-billing-admins@example.com"
  default_region       = "australia-southeast1"
}
```

Functional examples are included in the
[examples](./examples/) directory.

## Features

The Organization Bootstrap module will take the following actions:

1. Create a new GCP seed project using `project_prefix`.
1. Enable APIs in the seed project using `activate_apis`
1. Create a new service account for terraform in seed project
1. Create GCS bucket for Terraform state and grant access to service account
1. Grant IAM permissions required for CFT modules & Organization setup
    1. Overwrite organization wide project creator and billing account creator roles
    1. Grant Organization permissions to service account using `sa_org_iam_permissions`
    1. Grant access to billing account for service account
    1. Grant Organization permissions to `group_org_admins` using `org_admins_org_iam_permissions`
    1. Grant billing permissions to `group_billing_admins`
    1. (optional) Permissions required for service account impersonation using `sa_enable_impersonation`

For the cloudbuild submodule, see the README [cloudbuild](./modules/cloudbuild).


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| activate\_apis | List of APIs to enable in the seed project. | list(string) | `<list>` | no |
| billing\_account | The ID of the billing account to associate projects with. | string | n/a | yes |
| default\_region | Default region to create resources where applicable. | string | `"us-central-1"` | no |
| folder\_id | The ID of a folder to host this project | string | `""` | no |
| group\_billing\_admins | Google Group for GCP Billing Administrators | string | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | string | n/a | yes |
| org\_admins\_org\_iam\_permissions | List of permissions granted to the group supplied in group_org_admins variable across the GCP organization. | list(string) | `<list>` | no |
| org\_id | GCP Organization ID | string | n/a | yes |
| org\_project\_creators | Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required. | list(string) | `<list>` | no |
| project\_prefix | Name prefix to use for projects created. | string | `"cft"` | no |
| sa\_enable\_impersonation | Allow org_admins group to impersonate service account & enable APIs required. | bool | `"false"` | no |
| sa\_org\_iam\_permissions | List of permissions granted to Terraform service account across the GCP organization. | list(string) | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| gcs\_bucket\_tfstate | Bucket used for storing terraform state for foundations pipelines in seed project. |
| seed\_project\_id | Project where service accounts and core APIs will be enabled. |
| terraform\_sa\_email | Email for privileged service account. |
| terraform\_sa\_name | Fully qualified name for privileged service account. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

-   [gcloud sdk](https://cloud.google.com/sdk/install) >= 206.0.0
-   [Terraform](https://www.terraform.io/downloads.html) >= 0.12.6
-   [terraform-provider-google] plugin 2.1.x
-   [terraform-provider-google-beta] plugin 2.1.x

### Permissions

- `roles/resourcemanager.organizationAdmin` on GCP Organization
- `roles/billing.admin` on supplied billing account
- `roles/resourcemanager.projectCreator` on GCP Organization for `group_org_admins` group.
- Account running terraform should be a member of group provided in `group_org_admins` variable, otherwise they will loose `roles/resourcemanager.projectCreator` access. Additional members can be added by using the `org_project_creators` variable.

### Credentials

For users interested in using service account impersonation which this module helps enable with `sa_enable_impersonation`, please see this [blog post](https://medium.com/google-cloud/terraform-assume-role-and-service-account-impersonation-on-google-cloud-ffc553863e72) which explains how it works.

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Resource Manager API: `cloudresourcemanager.googleapis.com`
- Google Cloud Billing API: `cloudbilling.googleapis.com`
- Google Cloud IAM API: `iam.googleapis.com`
- Google Cloud Storage API `storage-api.googleapis.com`
- Google Cloud Service Usage API: `serviceusage.googleapis.com`

This API can be enabled in the default project created during establishing an organization.

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.
