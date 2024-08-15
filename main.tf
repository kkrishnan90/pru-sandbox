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

module "vpc" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/vpc"
  depends_on = [module.api_enabler] 
}

module "cloud_nat" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  network_id = module.vpc[each.key].network_id
  source     = "./modules/cloud-nat"
  depends_on = [module.api_enabler, module.vpc] 
}

module "firewall" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/firewall"
  depends_on = [module.api_enabler, module.vpc] 
}

module "service_account" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = module.vpc[each.key].project_id # Use the output from vpc module
  source     = "./modules/service-account"
  depends_on = [module.api_enabler] 
}



module "gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"

  instance_name = "ai-gpu-100-${random_id.instance_suffix.hex}"
  machine_type  = "g2-standard-4"
  depends_on = [module.api_enabler, module.vpc] 
}

module "non_gpu_notebook" {
  for_each   = { for i, v in local.project_ids : i => v }
  project_id = each.value 
  source     = "./modules/workbench-notebook"

  instance_name = "ai-no-gpu-100-${random_id.instance_suffix.hex}"
  machine_type  = "n1-standard-4"
  depends_on = [module.api_enabler, module.vpc] 
}
