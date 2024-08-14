output "cloudbuild_2nd_gen_connection" {
  description = "Cloudbuild connection created."
  value       = google_cloudbuildv2_connection.connection.id
}

output "cloudbuild_2nd_gen_repositories" {
  description = "Created repositories."
  value       = { for k, v in google_cloudbuildv2_repository.repositories : k => { "id" : v.id, "url" : v.remote_uri } }
}
