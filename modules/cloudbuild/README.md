## Overview


## Usage

Basic usage of this module is as follows:

```hcl
module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
  version = "~> 11.0"

  org_id         = "<ORGANIZATION_ID>"
  billing_account         = "<BILLING_ACCOUNT_ID>"
  group_org_admins        = "gcp-organization-admins@example.com"
  default_region          = "australia-southeast1"
  sa_enable_impersonation = true
  terraform_sa_email      = "<SERVICE_ACCOUNT_EMAIL>"
  terraform_sa_name       = "<SERVICE_ACCOUNT_NAME>"
  terraform_state_bucket  = "<GCS_STATE_BUCKET_NAME>"
}
```

Functional examples and sample Cloud Build definitions are included in the [examples](../../examples/) directory.

## Features

1. Create a new GCP cloud build project using `project_prefix`
1. Enable APIs in the cloud build project using `activate_apis`
1. Build a Terraform docker image for Cloud Build, including [terraform-validator](https://github.com/GoogleCloudPlatform/terraform-validator).
1. Create a GCS bucket for Cloud Build Artifacts using `project_prefix`
1. Create Cloud Source Repos for pipelines using list of repos in `cloud_source_repos`
    1. Create Cloud Build trigger for terraform apply on master branch
    1. Create Cloud Build trigger for terrafor plan on all other branches
1. Create KMS Keyring and key for encryption
    1. Grant access to decrypt to Cloud Build service account and `terraform_sa_email`
    1. Grant access to encrypt to `group_org_admins`
1. Optionally give Cloud Build service account permissions to impersonate terraform service account using `sa_enable_impersonation` and supplied value for `terraform_sa_name`



## Resources created

- KMS Keyring and key for secrets, including IAM for Cloudbuild, Org Admins and Terraform service acocunt
- (optional) Cloudbuild impersonation permissions for a service account
- (optional) Cloud Source Repos, with triggers for terraform plan (all other branches) & terraform apply (master)


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | List of APIs to enable in the Cloudbuild project. | `list(string)` | <pre>[<br>  "serviceusage.googleapis.com",<br>  "servicenetworking.googleapis.com",<br>  "compute.googleapis.com",<br>  "logging.googleapis.com",<br>  "bigquery.googleapis.com",<br>  "cloudresourcemanager.googleapis.com",<br>  "cloudbilling.googleapis.com",<br>  "iam.googleapis.com",<br>  "admin.googleapis.com",<br>  "appengine.googleapis.com",<br>  "storage-api.googleapis.com"<br>]</pre> | no |
| billing\_account | The ID of the billing account to associate projects with. | `string` | n/a | yes |
| cloud\_source\_repos | List of Cloud Source Repos to create with CloudBuild triggers. | `list(string)` | <pre>[<br>  "gcp-org",<br>  "gcp-networks",<br>  "gcp-projects"<br>]</pre> | no |
| cloudbuild\_apply\_filename | Path and name of Cloud Build YAML definition used for terraform apply. | `string` | `"cloudbuild-tf-apply.yaml"` | no |
| cloudbuild\_plan\_filename | Path and name of Cloud Build YAML definition used for terraform plan. | `string` | `"cloudbuild-tf-plan.yaml"` | no |
| create\_cloud\_source\_repos | If shared Cloud Source Repos should be created. | `bool` | `true` | no |
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| folder\_id | The ID of a folder to host this project | `string` | `""` | no |
| force\_destroy | If supplied, the logs and artifacts buckets will be deleted even while containing objects. | `bool` | `false` | no |
| gar\_repo\_name | Custom name to use for GAR repo. | `string` | `""` | no |
| gcloud\_version | Default gcloud image version. | `string` | `"504.0.0-slim"` | no |
| group\_org\_admins | Google Group for GCP Organization Administrators | `string` | n/a | yes |
| impersonate\_service\_account | The service account to impersonate while running the gcloud builds submit command. | `string` | `""` | no |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| project\_auto\_create\_network | Create the default network for the project created. | `bool` | `false` | no |
| project\_deletion\_policy | The deletion policy for the project created. | `string` | `"PREVENT"` | no |
| project\_id | Custom project ID to use for project created. | `string` | `""` | no |
| project\_labels | Labels to apply to the project. | `map(string)` | `{}` | no |
| project\_prefix | Name prefix to use for projects created. | `string` | `"cft"` | no |
| random\_suffix | Appends a 4 character random suffix to project ID and GCS bucket name. | `bool` | `true` | no |
| sa\_enable\_impersonation | Allow org\_admins group to impersonate service account & enable APIs required. | `bool` | `false` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| terraform\_apply\_branches | List of git branches configured to run terraform apply Cloud Build trigger. All other branches will run plan by default. | `list(string)` | <pre>[<br>  "main"<br>]</pre> | no |
| terraform\_sa\_email | Email for terraform service account. | `string` | n/a | yes |
| terraform\_sa\_name | Fully-qualified name of the terraform service account. | `string` | n/a | yes |
| terraform\_state\_bucket | Default state bucket, used in Cloud Build substitutions. | `string` | n/a | yes |
| terraform\_version | Default terraform version. | `string` | `"1.0.2"` | no |
| terraform\_version\_sha256sum | sha256sum for default terraform version. | `string` | `"7329f887cc5a5bda4bedaec59c439a4af7ea0465f83e3c1b0f4d04951e1181f4"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_project\_id | Project where CloudBuild configuration and terraform container image will reside. |
| csr\_repos | List of Cloud Source Repos created by the module, linked to Cloud Build triggers. |
| gcs\_bucket\_cloudbuild\_artifacts | Bucket used to store Cloud/Build artifacts in CloudBuild project. |
| gcs\_bucket\_cloudbuild\_logs | Bucket used to store Cloud/Build logs in CloudBuild project. |
| tf\_runner\_artifact\_repo | GAR Repo created to store runner images |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

-   [gcloud sdk](https://cloud.google.com/sdk/install) >= 206.0.0
-   [Terraform](https://www.terraform.io/downloads.html) >= 1.3
-   [terraform-provider-google] plugin 3.50.x

### Permissions

- `roles/billing.user` on supplied billing account
- `roles/resourcemanager.organizationAdmin` on GCP Organization
- `roles/resourcemanager.projectCreator` on GCP Organization or folder

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- Google Cloud Resource Manager API: `cloudresourcemanager.googleapis.com`
- Google Cloud Billing API: `cloudbilling.googleapis.com`
- Google Cloud IAM API: `iam.googleapis.com`
- Google Cloud Storage API `storage-api.googleapis.com`
- Google Cloud Service Usage API: `serviceusage.googleapis.com`
- Google Cloud Build API: `cloudbuild.googleapis.com`
- Google Cloud KMS API: `cloudkms.googleapis.com`

If using Cloud Source Repositories, Google Cloud Source Repo API: `sourcerepo.googleapis.com` must also be enabled.

This API can be enabled in the default project created during establishing an organization.

## Contributing

Refer to the [contribution guidelines](../../CONTRIBUTING.md) for
information on contributing to this module.
