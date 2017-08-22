# Configure the Google Cloud provider
provider "google" {
  credentials = "${file("${var.gcp_credentials}")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

# Master instance
# https://www.terraform.io/docs/providers/google/r/sql_database_instance.html

resource "google_sql_database_instance" "master" {
  name    = "${var.cloudsql_master_name}"
  region  = "${var.gcp_region}"
  project = "${var.gcp_project}"

  database_version = "${var.cloudsql_version}"

  settings {
    tier      = "${var.cloudsql_tier}"
    disk_type = "${var.disk_type}"

    location_preference {
      zone = "${var.master_location_preference_zone}"
    }

    backup_configuration {
      enabled            = "${var.backup_enabled}"
      start_time         = "${var.backup_start_time}"
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "character_set_server"
      value = "${var.database_charset}"
    }
  }
}

# Failover replica
# https://www.terraform.io/docs/providers/google/r/sql_database_instance.html

resource "google_sql_database_instance" "failover" {
  name                 = "${var.cloudsql_master_name}-failover"
  master_instance_name = "${var.cloudsql_master_name}"
  region               = "${var.gcp_region}"
  project              = "${var.gcp_project}"

  database_version = "${var.cloudsql_version}"

  replica_configuration {
    failover_target = true
  }

  settings {
    tier = "${var.cloudsql_tier}"

    location_preference {
      zone = "${var.failover_location_preference_zone}"
    }
  }
}

# User configuration

resource "google_sql_user" "users" {
  name     = "${var.cloudsql_username}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "${var.cloudsql_userhost}"
  password = "${var.cloudsql_userpass}"
}

# Database configuration

resource "google_sql_database" "default" {
  name      = "${var.database_name}"
  instance  = "${google_sql_database_instance.master.name}"
  charset   = "${var.database_charset}"
  collation = "${var.database_collation}"
}
