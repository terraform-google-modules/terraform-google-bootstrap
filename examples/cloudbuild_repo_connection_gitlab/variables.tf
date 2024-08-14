variable "project_id" {
  description = "The ID of the project in which to provision resources."
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

variable "gitlab_authorizer_credential" {
  description = "Credential for GitLab authorizer"
  type        = string
}

variable "gitlab_read_authorizer_credential" {
  description = "Credential for GitLab read authorizer"
  type        = string
}