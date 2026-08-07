resource "google_storage_bucket" "frontend" {
  name          = "www.arms-tracker.app"
  location      = "EU"
  force_destroy = false

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page = "index.html"
  }
}

resource "google_storage_bucket_iam_member" "frontend_public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Same classic same-name-bucket hosting pattern as the production bucket
# above - dev.arms-tracker.app CNAMEs to the same fixed c.storage.googleapis.com
# target, and GCS tells the two buckets apart by matching the (Cloudflare-
# preserved) Host header against each bucket's own name.
resource "google_storage_bucket" "frontend_dev" {
  name          = "dev.arms-tracker.app"
  location      = "EU"
  force_destroy = false

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

resource "google_storage_bucket_iam_member" "frontend_dev_public_read" {
  bucket = google_storage_bucket.frontend_dev.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
