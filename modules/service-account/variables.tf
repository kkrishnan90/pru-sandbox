variable "project_id" {
  type = string
}

variable "service_account_name" {
  type = string
  default = "project-service-account"
}

variable "roles" {
  type = list(string)
  default = [
    "roles/aiplatform.user",
    "roles/notebooks.viewer",
    "roles/storage.admin",
  ]
}

variable "gsuite_user" {
  type = string
  # default = "gsglife.gcppruaisandbox.reader@prugcp.com"
  default="kkrish@google.com"
}
