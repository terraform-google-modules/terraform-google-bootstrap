variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "github_pat" {
  description = "The personal access token for authenticating with GitHub."
  type        = string
}

variable "github_app_id" {
  description = "The application ID for the Cloudbuild GitHub app."
  type        = string
}

variable "test_repo_url" {
  description = "The HTTPS clone URL of the test repository, ending with .git."
  type        = string
}

variable "test_repo_name" {
  description = "The name of the test repository."
  type        = string
}

