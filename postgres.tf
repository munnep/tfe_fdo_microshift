
resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres-secret"
    namespace = var.namespace
  }
  data = {
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
    POSTGRES_DB       = var.postgres_db
  }
  type = "Opaque"
}

resource "kubernetes_pod" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres"
    namespace = var.namespace
    labels    = { app = "postgres" }
    annotations = {
      "openshift.io/scc" = "nonroot-v2"
    }
  }
  spec {
    security_context {
      run_as_non_root = true
      run_as_user     = 70
      run_as_group    = 70
      fs_group        = 70
      seccomp_profile {
        type = "RuntimeDefault"
      }
    }

    container {
      name  = "postgres"
      image = var.image_postgres

      security_context {
        allow_privilege_escalation = false
        capabilities {
          drop = ["ALL"]
        }
        run_as_non_root = true
        run_as_user     = 70
        run_as_group    = 70
        seccomp_profile {
          type = "RuntimeDefault"
        }
      }

      port { container_port = 5432 }

      env {
        name = "POSTGRES_USER"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_USER"
          }
        }
      }
      env {
        name = "POSTGRES_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_PASSWORD"
          }
        }
      }
      env {
        name = "POSTGRES_DB"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_DB"
          }
        }
      }
      env {
        name  = "PGDATA"
        value = "/var/lib/postgresql/data/pgdata"
      }

      readiness_probe {
        exec { command = ["/bin/sh", "-c", "pg_isready -U $POSTGRES_USER"] }
        initial_delay_seconds = 5
        period_seconds        = 5
      }
      liveness_probe {
        exec { command = ["/bin/sh", "-c", "pg_isready -U $POSTGRES_USER"] }
        initial_delay_seconds = 30
        period_seconds        = 10
        failure_threshold     = 6
      }

      resources {}

      volume_mount {
        name       = "pgdata"
        mount_path = "/var/lib/postgresql/data"
      }
    }

    volume {
      name = "pgdata"
      empty_dir {}
    }
    restart_policy = "Always"
  }

  lifecycle {
    ignore_changes = [
      spec[0].security_context,
      metadata[0].annotations["security.openshift.io/validated-scc-subject-type"],
    ]
  }

}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres"
    namespace = var.namespace
    labels    = { app = "postgres" }
  }
  spec {
    selector = { app = "postgres" }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
    type = "LoadBalancer"
  }
  wait_for_load_balancer = false
}

# output "postgres_service_name" {
#   value = kubernetes_service.postgres.metadata[0].name
# }

# output "postgres_endpoint" {
#   value = "${kubernetes_service.postgres.metadata[0].name}.${var.namespace}.svc.cluster.local:${kubernetes_service.postgres.spec[0].port[0].port}"
# }

output "postgres_url" {
  value = "postgresql://${var.postgres_user}:${var.postgres_password}@localhost:${kubernetes_service.postgres.spec[0].port[0].port}/${var.postgres_db}"
}
