output "cloudbuild_2nd_gen_connection" {
  description = "Cloudbuild connection created."
  value       = module.gitlab_connection.cloudbuild_2nd_gen_connection
}

output "cloudbuild_2nd_gen_repositories" {
  description = "Created repositories."
  value       = module.gitlab_connection.cloudbuild_2nd_gen_repositories
}
