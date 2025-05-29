/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
locals {
  bootstrap_project_number           = module.project.project_number
  gitlab_network_name                = "default"
  gitlab_network_id                  = "projects/${module.gitlab_project.project_number}/locations/global/networks/${local.gitlab_network_name}"
  gitlab_network_id_without_location = replace(local.gitlab_network_id, "locations/", "")
  gitlab_network_url                 = "https://www.googleapis.com/compute/v1/projects/${module.gitlab_project.project_id}/global/networks/${local.gitlab_network_name}"
}

resource "google_project_iam_member" "allow_gitlab_bucket_download" {
  project = module.gitlab_project.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_project_iam_member" "allow_gitlab_iam_policy_edit" {
  project = module.gitlab_project.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.int_test.email}"
}

module "gitlab_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                     = "eab-gitlab-self-hosted"
  random_project_id        = "true"
  random_project_id_length = 4
  org_id                   = var.org_id
  folder_id                = module.folder_seed.id
  billing_account          = var.billing_account
  deletion_policy          = "DELETE"
  default_service_account  = "KEEP"

  auto_create_network = true

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
    "storage.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

resource "time_sleep" "wait_gitlab_project_apis" {
  depends_on = [module.gitlab_project, module.vpc]

  create_duration = "30s"
}

resource "google_service_account" "gitlab_vm" {
  account_id   = "gitlab-vm-sa"
  project      = module.gitlab_project.project_id
  display_name = "Custom SA for VM Instance"
}

resource "google_project_iam_member" "secret_manager_admin_vm_instance" {
  project = module.gitlab_project.project_id
  role    = "roles/secretmanager.admin"
  member  = google_service_account.gitlab_vm.member
}

resource "google_service_account_iam_member" "impersonate" {
  service_account_id = google_service_account.gitlab_vm.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_project_iam_member" "int_test_gitlab_permissions" {
  for_each = toset([
    "roles/compute.instanceAdmin",
    "roles/secretmanager.admin"
  ])
  project = module.gitlab_project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.int_test.email}"
}

resource "google_compute_instance" "default" {
  name         = "gitlab"
  project      = module.gitlab_project.project_id
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"

  tags = ["git-vm", "direct-gateway-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = local.gitlab_network_name
    access_config {
      // Ephemeral public IP
    }
    subnetwork         = "gitlab-vm-subnet"
    subnetwork_project = module.vpc.project_id
  }

  metadata_startup_script = file("./scripts/gitlab_self_hosted.sh")

  service_account {
    email  = google_service_account.gitlab_vm.email
    scopes = ["cloud-platform"]
  }

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

resource "google_secret_manager_secret" "gitlab_webhook" {
  project   = module.gitlab_project.project_id
  secret_id = "gitlab-webhook"
  replication {
    auto {}
  }

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

resource "random_uuid" "random_webhook_secret" {
}

resource "google_secret_manager_secret_version" "gitlab_webhook" {
  secret      = google_secret_manager_secret.gitlab_webhook.id
  secret_data = random_uuid.random_webhook_secret.result
}

// ================================
//          FIREWALL RULES
// ================================

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = local.gitlab_network_name
  project = module.gitlab_project.project_id

  allow {
    ports    = [22]
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

resource "google_compute_firewall" "allow_service_networking" {
  name    = "allow-service-networking"
  network = local.gitlab_network_name
  project = module.gitlab_project.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["35.199.192.0/19"]

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = local.gitlab_network_name
  project = module.gitlab_project.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["git-vm"]

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = local.gitlab_network_name
  project = module.gitlab_project.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["git-vm"]

  depends_on = [time_sleep.wait_gitlab_project_apis]
}

// =======================================================
//          GITLAB WORKER POOL AND PRIVATE DNS CONFIG
// =======================================================

resource "google_storage_bucket" "ssl_cert" {
  name          = "${module.gitlab_project.project_id}-ssl-cert"
  project       = module.gitlab_project.project_id
  location      = "us-central1"
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.ssl_cert.name
  role   = "roles/storage.admin"
  member = google_service_account.gitlab_vm.member
}

resource "google_service_directory_namespace" "gitlab" {
  provider     = google-beta
  namespace_id = "gitlab-namespace"
  location     = "us-central1"
  project      = module.gitlab_project.project_id
}

resource "google_service_directory_service" "gitlab" {
  provider   = google-beta
  service_id = "gitlab"
  namespace  = google_service_directory_namespace.gitlab.id
}

resource "google_service_directory_endpoint" "gitlab" {
  provider    = google-beta
  endpoint_id = "endpoint"
  service     = google_service_directory_service.gitlab.id

  network = local.gitlab_network_id
  address = google_compute_instance.default.network_interface[0].network_ip
  port    = 443
}

resource "google_dns_managed_zone" "sd_zone" {
  provider = google-beta

  name        = "peering-zone"
  dns_name    = "example.com."
  description = "Example private DNS Service Directory zone for Gitlab Instance"
  project     = module.gitlab_project.project_id

  visibility = "private"

  service_directory_config {
    namespace {
      namespace_url = google_service_directory_namespace.gitlab.id
    }
  }

  private_visibility_config {
    networks {
      network_url = local.gitlab_network_url
    }
  }
}

resource "google_project_iam_member" "sd_viewer" {
  project = module.gitlab_project.project_id
  role    = "roles/servicedirectory.viewer"
  member  = "serviceAccount:service-${local.bootstrap_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "access_network" {
  project = module.gitlab_project.project_id
  role    = "roles/servicedirectory.pscAuthorizedService"
  member  = "serviceAccount:service-${local.bootstrap_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cb_agent_pool_user" {
  project = module.gitlab_project.project_id
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:service-${local.bootstrap_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cb_sa_pool_user" {
  project = module.gitlab_project.project_id
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:${local.bootstrap_project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_compute_global_address" "worker_range" {
  project       = module.gitlab_project.project_id
  name          = "worker-pool-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.3.3.0"
  prefix_length = 24
  network       = local.gitlab_network_id_without_location
}

resource "google_service_networking_connection" "gitlab_worker_pool_conn" {
  network                 = local.gitlab_network_id_without_location
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.worker_range.name]
  depends_on              = [google_project_service.servicenetworking]
}

resource "google_project_service" "servicenetworking" {
  project            = module.gitlab_project.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloudbuild_worker_pool" "pool" {
  name     = "cb-pool"
  project  = module.gitlab_project.project_id
  location = "us-central1"
  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-standard-4"
    no_external_ip = true
  }
  network_config {
    peered_network          = local.gitlab_network_id_without_location
    peered_network_ip_range = "/24"
  }

  depends_on = [google_service_networking_connection.gitlab_worker_pool_conn]
}

resource "time_sleep" "wait_service_network_peering" {
  depends_on = [google_service_networking_connection.gitlab_worker_pool_conn]

  create_duration = "30s"
}

resource "google_service_networking_peered_dns_domain" "name" {
  project    = module.gitlab_project.project_id
  name       = "example-com"
  network    = local.gitlab_network_name
  dns_suffix = "example.com."

  depends_on = [
    google_dns_managed_zone.sd_zone,
    time_sleep.wait_service_network_peering
  ]
}

// ===========================
//          OUTPUTS
// ===========================
output "gitlab_webhook_secret_id" {
  value = google_secret_manager_secret.gitlab_webhook.id
}

output "gitlab_pat_secret_name" {
  value = "gitlab-pat-from-vm"
}

output "gitlab_project_number" {
  value = module.gitlab_project.project_number
}

output "gitlab_url" {
  value = "https://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}.nip.io"
}

output "gitlab_internal_ip" {
  value = google_compute_instance.default.network_interface[0].network_ip
}

output "gitlab_secret_project" {
  value = module.gitlab_project.project_id
}

output "gitlab_instance_zone" {
  value = google_compute_instance.default.zone
}

output "gitlab_instance_name" {
  value = google_compute_instance.default.name
}

output "gitlab_service_directory" {
  value = google_service_directory_service.gitlab.id
}

output "workerpool_id" {
  value = google_cloudbuild_worker_pool.pool.id
}
