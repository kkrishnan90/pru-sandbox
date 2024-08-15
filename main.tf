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
}

module "firewall" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  network_id = local.vpc_network_ids[each.key] # Pass network ID as input
  source     = "./modules/firewall"
}

module "service_account" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value
  source     = "./modules/service-account"
}

module "gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"
  network    = local.vpc_network_ids[each.key] # Pass network ID as input
  instance_name = "ai-gpu-100-${random_id.instance_suffix.hex}"
  service_account = "tf-project-sa@${each.value}.iam.gserviceaccount.com"
  machine_type  = "g2-standard-4"
}

module "non_gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"
  network    = local.vpc_network_ids[each.key] # Pass network ID as input
  instance_name = "ai-no-gpu-100-${random_id.instance_suffix.hex}"
  service_account = "tf-project-sa@${each.value}.iam.gserviceaccount.com"
  machine_type  = "n1-standard-4"
}

locals {
  project_roles = flatten([
    for project_id in local.project_ids : [
      for role in [
        "roles/notebooks.runner",
        "roles/notebooks.viewer",
        "roles/aiplatform.user",
        "roles/iam.serviceAccountUser",
        "roles/storage.admin",
      ] : {
        project_id = project_id
        role       = role
      }
    ]
  ])
}

resource "google_project_iam_member" "tf_project_sa_roles" {
  for_each = {
    for pr in local.project_roles : "${pr.project_id}-${pr.role}" => pr
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:tf-project-sa@${each.value.project_id}.iam.gserviceaccount.com"
}

