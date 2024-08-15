resource "google_service_account" "default" {
  account_id   = var.service_account_name
  disabled     = false
  display_name = "Default Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.roles)
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.default.email}"
}
