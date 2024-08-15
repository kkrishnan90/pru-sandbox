variable "project_id" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "zone" {
  type = string
  default = "asia-southeast1-a"
}


variable "machine_type" {
  type = string
}

variable "network" {
  type = string
}

variable "service_account" {
  type = string
}
