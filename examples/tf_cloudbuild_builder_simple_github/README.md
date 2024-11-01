## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_builder](../../modules/tf_cloudbuild_builder/) module with a Cloud Build repositories (2nd gen) GitHub repository.

For GitHub connections you will need:

- Install the [Cloud Build App](https://github.com/apps/google-cloud-build) on Github.
- Create a [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) on Github with [scopes](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes) `repo` and `read:user` (or if app is installed in a organization use `read:org`).
- Create two [Google Secret Manager](https://cloud.google.com/secret-manager/docs/overview) secrets, one for the Cloud Build App and one for the Personal Access Token.
- Populate the corresponding [secret versions](https://cloud.google.com/secret-manager/docs/add-secret-version) of each one of the secrets.

For more information on this topic refer to the Cloud Build repositories (2nd gen) documentation for
[Connect to a GitHub repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| github\_app\_id\_secret\_id | The secret ID for the application ID for the Cloudbuild GitHub app. | `string` | n/a | yes |
| github\_pat\_secret\_id | The secret ID for the personal access token for authenticating with GitHub. | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the GitHub repository where the Terraform configs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_repo | GAR Repo created to store TF Cloud Builder images |
| cloudbuild\_trigger\_id | Trigger used for building new TF Builder |
| location | The location in which the resources were provisioned |
| project\_id | The ID of the project in which the resources were provisioned |
| repository\_id | ID of the Cloud Build repositories (2nd gen) repository |
| scheduler\_id | Scheduler ID for periodically triggering TF Builder build Workflow |
| workflow\_id | Workflow ID for triggering new TF Builder build |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
