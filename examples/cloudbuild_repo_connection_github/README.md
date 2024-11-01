## Overview

The example will create Cloud Build repositories (2nd gen) using a Github connection.

## Github Requirements for Cloud Build Connection

When using a Cloud Build repositories (2nd gen) GitHub repository, a Cloud Build connection to your repository provider will be created.

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
| repository\_name | The name of the test repository. | `string` | n/a | yes |
| repository\_url | The HTTPS clone URL of the repository, ending with .git. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cloud\_build\_repositories\_2nd\_gen\_connection | Cloudbuild connection created. |
| cloud\_build\_repositories\_2nd\_gen\_repositories | Created repositories. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
