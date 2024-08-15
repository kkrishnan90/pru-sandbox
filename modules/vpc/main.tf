resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = true
}
output "network_id" {
  value = google_compute_network.vpc_network.id
}
output "project_id" {
  value = var.project_id
}
