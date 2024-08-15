terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.41.0"
    }
  }
}

locals {
  project_ids = split("\n", file("projects.txt"))
}

resource "local_file" "project_count" {
  content  = length(local.project_ids)
  filename = "project_count.txt"
}

resource "random_id" "instance_suffix" {
  byte_length = 4
}

# Loop through each project ID for modules
module "api_enabler" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/api-enabler"
}

# Create VPCs outside the module dependencies
resource "google_compute_network" "vpc_network" {
  for_each = { for i, v in local.project_ids : i => v }
  project                 = each.value
  name                    = "my-vpc-${each.key}"
  auto_create_subnetworks = true
}


# Get VPC network IDs for each project
locals {
  vpc_network_ids = { for i, v in local.project_ids : i => google_compute_network.vpc_network[i].id }
}

module "cloud_nat" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  network_id = local.vpc_network_ids[each.key] # Pass network ID as input
  source     = "./modules/cloud-nat"
  depends_on = [module.api_enabler]  # Remove dependency on VPC resource
}

module "firewall" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/firewall"
  depends_on = [module.api_enabler, google_compute_network.vpc_network] 
}

module "service_account" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value
  source     = "./modules/service-account"
  depends_on = [module.api_enabler] 
}

module "gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"

  instance_name = "ai-gpu-100-${random_id.instance_suffix.hex}"
  machine_type  = "g2-standard-4"
  depends_on = [module.api_enabler, google_compute_network.vpc_network,module.firewall,module.cloud_nat,module.service_account] 
}

module "non_gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"

  instance_name = "ai-no-gpu-100-${random_id.instance_suffix.hex}"
  machine_type  = "n1-standard-4"
  depends_on = [module.api_enabler, google_compute_network.vpc_network,module.firewall,module.cloud_nat,module.service_account] 
}
