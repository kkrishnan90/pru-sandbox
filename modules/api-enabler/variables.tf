variable "project_id" {
  type = string
}

variable "apis" {
  type = list(string)
  default = [
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "notebooks.googleapis.com",
    "dataflow.googleapis.com",
    "artifactregistry.googleapis.com",
    "datalineage.googleapis.com",
    "datacatalog.googleapis.com",
    "compute.googleapis.com",
    "dataform.googleapis.com",
    "vision.googleapis.com",
  ]
}
