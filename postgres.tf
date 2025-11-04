
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

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "15Gi"
      }
    }
  }
}

resource "kubernetes_pod" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres"
    namespace = var.namespace
    labels    = { app = "postgres" }
  }
  spec {
    container {
      name  = "postgres"
      image = var.image_postgres

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
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
      }
    }
    restart_policy = "Always"
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
