## Overview

TF Cloud Build Workspace blueprint creates an opinionated workflow for actuating Terraform on Cloud Build. A set of Cloud Build triggers manage plan and apply operations on a root configuration stored in a VCS repo. Cloud Build triggers use a per workspace Service Account which can be configured with minimal permissions required by a given Terraform configuration. Optionally dedicated GCS buckets for state and log storage are also created.

## Usage

Basic usage of this module is as follows:

```hcl
module "tf-net-workspace" {
  source  = "terraform-google-modules/bootstrap/google//modules/tf_cloudbuild_workspace"
  version = "~> 6.1"

  project_id              = var.project_id
  tf_repo_uri             = "https://github.com/org/tf-config-repo"
  cloudbuild_sa_roles     = { var.project_id = ["roles/compute.networkAdmin"] }
}
```

Functional examples are included in the [examples](../../examples/) directory.

## Resources created

This module creates:
- Two Cloud Build triggers with an inline build configuration for planning and applying Terraform configuration. Optionaly custom in repo build configs can be specified.
- Optional custom Service Account and roles for that SA used by Cloud Build triggers.
- GCS buckets for storing Terraform state, logs and plans.

![](./assets/arch.png)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| buckets\_force\_destroy | When deleting the bucket for storing CloudBuild logs/TF state, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| cloudbuild\_apply\_filename | Optional Cloud Build YAML definition used for terraform apply. Defaults to using inline definition. | `string` | `null` | no |
| cloudbuild\_env\_vars | Optional list of environment variables to be used in builds. List of strings of form KEY=VALUE expected. | `list(string)` | `[]` | no |
| cloudbuild\_plan\_filename | Optional Cloud Build YAML definition used for terraform plan. Defaults to using inline definition. | `string` | `null` | no |
| cloudbuild\_sa | Custom SA email to be used by the CloudBuild trigger. Defaults to being created if empty. | `string` | `""` | no |
| cloudbuild\_sa\_roles | Optional to assign to custom CloudBuild SA. Map of project id to list of roles expected. | `map(list(string))` | `{}` | no |
| location | Location for build logs/state bucket | `string` | `"us-central1"` | no |
| prefix | Prefix of the state/log buckets and triggers planning/applying config. If unset computes a prefix from tf\_repo\_uri and tf\_repo\_dir variables. | `string` | `""` | no |
| project\_id | GCP project for Cloud Build triggers, state and log buckets. | `string` | n/a | yes |
| state\_bucket\_self\_link | Custom GCS bucket for storing TF state. Defaults to being created if empty. | `string` | `""` | no |
| substitutions | Map of substitutions to use in builds. | `map(string)` | `{}` | no |
| tf\_apply\_branches | List of git branches configured to run terraform apply Cloud Build trigger. All other branches will run plan by default. | `list(string)` | <pre>[<br>  "main"<br>]</pre> | no |
| tf\_cloudbuilder | Name of the Cloud Builder image used for running build steps. | `string` | `"hashicorp/terraform:1.2.2"` | no |
| tf\_repo\_dir | The directory inside the repo where the Terrafrom root config is located. If empty defaults to repo root. | `string` | `""` | no |
| tf\_repo\_type | Type of repo | `string` | `"CLOUD_SOURCE_REPOSITORIES"` | no |
| tf\_repo\_uri | The URI of the repo where Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloudbuild\_apply\_trigger\_id | Trigger used for running TF apply |
| cloudbuild\_plan\_trigger\_id | Trigger used for running TF plan |
| cloudbuild\_sa | SA used by Cloud Build triggers |
| logs\_bucket | Bucket for storing TF logs/plans |
| state\_bucket | Bucket for storing TF state |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Software

-   [Terraform](https://www.terraform.io/downloads.html) >= 0.13.0
-   [terraform-provider-google] plugin >= 3.50.x

### Permissions

- `roles/cloudbuild.builds.editor`
- `roles/storage.admin`
- `roles/iam.serviceAccountCreator`

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

```hcl
"iam.googleapis.com",
"compute.googleapis.com",
"cloudbuild.googleapis.com",
```

## Contributing

Refer to the [contribution guidelines](../../CONTRIBUTING.md) for
information on contributing to this module.
