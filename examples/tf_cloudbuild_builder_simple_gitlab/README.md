## Overview

This example demonstrates the simplest usage of the [tf_cloudbuild_builder](../../modules/tf_cloudbuild_builder/) module with a Cloud Build repositories (2nd gen) GitLab repository.

For GitLab connections you will need:

- Create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) on GitLab with [scope](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#personal-access-token-scopes) `api`.
- Create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) on GitLab with [scope](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#personal-access-token-scopes) `read_api`.
- Create a [webhook](https://docs.gitlab.com/ee/user/project/integrations/webhooks.html)
- Create three [Google Secret Manager](https://cloud.google.com/secret-manager/docs/overview) secrets, one for the `api` token, one for the `read_api` token, and one for the `webhook`.
- Populate the corresponding [secret versions](https://cloud.google.com/secret-manager/docs/add-secret-version) of each one of the secrets.

For more information on this topic refer to the Cloud Build repositories (2nd gen) documentation:
- [Connect to a GitLab host](https://cloud.google.com/build/docs/automating-builds/gitlab/connect-host-gitlab)
- [Connect to a GitLab repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gitlab\_authorizer\_secret\_id | The secret ID for the credential for GitLab authorizer | `string` | n/a | yes |
| gitlab\_read\_authorizer\_secret\_id | The secret ID for the credential for GitLab read authorizer | `string` | n/a | yes |
| gitlab\_webhook\_secret\_id | The secret ID for the WebHook for GitLab | `string` | n/a | yes |
| project\_id | The ID of the project in which to provision resources. | `string` | n/a | yes |
| repository\_uri | The URI of the GitLab repository where the Terraform configs are stored. | `string` | n/a | yes |

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
