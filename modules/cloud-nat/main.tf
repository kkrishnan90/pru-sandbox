resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = var.network_id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "default-cloud-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option            = "AUTO_ONLY"
  project                            = var.project_id
}

variable "network_id" {
  type = string
}