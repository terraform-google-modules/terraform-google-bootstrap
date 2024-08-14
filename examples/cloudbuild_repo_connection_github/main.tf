
module "github_connection" {
  source = "../../modules/cloudbuild_repo_connection"

  project_id = var.project_id
  credential_config = {
    credential_type = "GITHUBv2"
    github_pat      = var.github_pat
    github_app_id   = var.github_app_id
  }

  cloudbuild_repos = {
    "test_repo" = {
      repo_name = var.test_repo_name
      repo_url  = var.test_repo_url
    },
  }
}
