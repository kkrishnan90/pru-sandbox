resource "google_workbench_instance" "default" {
  name         = var.instance_name
  location     = var.zone
  project      = var.project_id
  gce_setup {
    machine_type = var.machine_type
    disable_public_ip = true
   shielded_instance_config {
      enable_secure_boot = true
      enable_vtpm = true
      enable_integrity_monitoring = true
    }
    network_interfaces {
      network = var.network
    }
    service_accounts {
     email = var.service_account
    }

  }

}


