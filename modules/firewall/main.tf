resource "google_compute_firewall" "allow_egress" {
  project  = var.project_id
  network = var.network_id
  name     = "allow-egress-all"
  priority = 1000

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  destination_ranges = ["0.0.0.0/0"]
}
