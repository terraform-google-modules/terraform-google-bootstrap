# terraform-google-bootstrap

The purpose of this module is to help bootstrap a GCP organization, creating all the required GCP resources & permissions to start using the Cloud Foundation Toolkit (CFT). For users who want to use Cloud Build & Cloud Source Repos for foundations code, there is also a submodule to help bootstrap all the required resources to do this.

## Usage

Basic usage of this module is as follows:

```hcl
module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
  version = "~> 11.0"

  org_id               = "<ORGANIZATION_ID>"
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

1. Create a new GCP seed project using `project_prefix`. Use `project_id` if you need to use custom project ID.
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
|------|-------------|------|---------|:--------:|
| activate\_apis | List of APIs to enable in the seed project. | `list(string)` | <pre>[<br>  "serviceusage.googleapis.com",<br>  "servicenetworking.googleapis.com",<br>  "compute.googleapis.com",<br>  "logging.googleapis.com",<br>  "bigquery.googleapis.com",<br>  "cloudresourcemanager.googleapis.com",<br>  "cloudbilling.googleapis.com",<br>  "iam.googleapis.com",<br>  "admin.googleapis.com",<br>  "appengine.googleapis.com",<br>  "storage-api.googleapis.com",<br>  "monitoring.googleapis.com"<br>]</pre> | no |
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| create\_terraform\_sa | If the Terraform service account should be created. | `bool` | `true` | no |
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| encrypt\_gcs\_bucket\_tfstate | Encrypt bucket used for storing terraform state files in seed project. | `bool` | `false` | no |
| folder\_id | The ID of a folder to host this project | `string` | `""` | no |
| force\_destroy | If supplied, the state bucket will be deleted even while containing objects. | `bool` | `false` | no |
| grant\_billing\_user | Grant roles/billing.user role to CFT service account | `bool` | `true` | no |
| group\_billing\_admins | Google Group for GCP Billing Administrators | `string` | n/a | yes |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| key\_protection\_level | The protection level to use when creating a version based on this template. Default value: "SOFTWARE" Possible values: ["SOFTWARE", "HSM"] | `string` | `"SOFTWARE"` | no |
| key\_rotation\_period | The rotation period of the key. | `string` | `null` | no |
| kms\_prevent\_destroy | Set the prevent\_destroy lifecycle attribute on keys. | `bool` | `true` | no |
| org\_admins\_org\_iam\_permissions | List of permissions granted to the group supplied in group\_org\_admins variable across the GCP organization. | `list(string)` | <pre>[<br>  "roles/billing.user",<br>  "roles/resourcemanager.organizationAdmin"<br>]</pre> | no |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| org\_project\_creators | Additional list of members to have project creator role accross the organization. Prefix of group: user: or serviceAccount: is required. | `list(string)` | `[]` | no |
| parent\_folder | GCP parent folder ID in the form folders/{id} | `string` | `""` | no |
| project\_auto\_create\_network | Create the default network for the project created. | `bool` | `false` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |
| project\_id | Custom project ID to use for project created. If not supplied, the default id is {project\_prefix}-seed-{random suffix}. | `string` | `""` | no |
| project\_labels | Labels to apply to the project. | `map(string)` | `{}` | no |
| project\_prefix | Name prefix to use for projects created. | `string` | `"cft"` | no |
| random\_suffix | Appends a 4 character random suffix to project ID and GCS bucket name. | `bool` | `true` | no |
| sa\_enable\_impersonation | Allow org\_admins group to impersonate service account & enable APIs required. | `bool` | `false` | no |
| sa\_org\_iam\_permissions | List of permissions granted to Terraform service account across the GCP organization. | `list(string)` | <pre>[<br>  "roles/billing.user",<br>  "roles/compute.networkAdmin",<br>  "roles/compute.xpnAdmin",<br>  "roles/iam.securityAdmin",<br>  "roles/iam.serviceAccountAdmin",<br>  "roles/logging.configWriter",<br>  "roles/orgpolicy.policyAdmin",<br>  "roles/resourcemanager.folderAdmin",<br>  "roles/resourcemanager.organizationViewer"<br>]</pre> | no |
| state\_bucket\_name | Custom state bucket name. If not supplied, the default name is {project\_prefix}-tfstate-{random suffix}. | `string` | `""` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| tf\_service\_account\_id | ID of service account for terraform in seed project | `string` | `"org-terraform"` | no |
| tf\_service\_account\_name | Display name of service account for terraform in seed project | `string` | `"CFT Organization Terraform Account"` | no |

## Outputs

| Name | Description |
|------|-------------|
| gcs\_bucket\_tfstate | Bucket used for storing terraform state for foundations pipelines in seed project. |
| seed\_project\_id | Project where service accounts and core APIs will be enabled. |
| terraform\_sa\_email | Email for privileged service account for Terraform. |
| terraform\_sa\_name | Fully qualified name for privileged service account for Terraform. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

-   [gcloud sdk](https://cloud.google.com/sdk/install) >= 206.0.0
-   [Terraform](https://www.terraform.io/downloads.html) >= 1.3
-   [terraform-provider-google] plugin 3.50.x

### Permissions

- `roles/resourcemanager.organizationAdmin` on GCP Organization
- `roles/orgpolicy.policyAdmin` on GCP Organization
- `roles/billing.admin` on supplied billing account
- Account running terraform should be a member of group provided in `group_org_admins` variable, otherwise they will loose `roles/resourcemanager.projectCreator` access. Additional members can be added by using the `org_project_creators` variable.

### Credentials

For users interested in using service account impersonation which this module helps enable with `sa_enable_impersonation`, please see this [blog post](https://cloud.google.com/blog/topics/developers-practitioners/using-google-cloud-service-account-impersonation-your-terraform-code) which explains how it works.

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
