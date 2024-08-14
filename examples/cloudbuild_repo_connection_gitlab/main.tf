
module "gitlab_connection" {
  source = "../../modules/cloudbuild_repo_connection"

  project_id = var.project_id
  credential_config = {
    credential_type                   = "GITLABv2"
    gitlab_authorizer_credential      = var.gitlab_authorizer_credential
    gitlab_read_authorizer_credential = var.gitlab_read_authorizer_credential
  }

  cloudbuild_repos = {
    "test_repo" = {
      repo_name = var.test_repo_name
      repo_url  = var.test_repo_url
    },
  }
}
