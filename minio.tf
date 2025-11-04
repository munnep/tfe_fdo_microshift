# Root + app credentials secret
resource "kubernetes_secret" "minio_root" {
  metadata {
    name      = "${var.tag_prefix}-minio-root-credentials"
    namespace = var.namespace
  }
  data = {
    rootUser     = var.minio_user
    rootPassword = var.minio_password
    appAccessKey = var.minio_access_key
    appSecretKey = var.minio_secret_key
  }
  type = "Opaque"
}

resource "kubernetes_pod" "minio" {
  metadata {
    name      = "${var.tag_prefix}-minio"
    namespace = var.namespace
    labels = {
      app     = "minio"
      storage = "ephemeral"
    }
    annotations = {
      "openshift.io/scc" = "nonroot-v2"
    }
  }
  spec {
    security_context {
      run_as_non_root = true
      run_as_user     = 1001
      run_as_group    = 1001
      seccomp_profile {
        type = "RuntimeDefault"
      }
    }

    container {
      name  = "minio"
      image = var.image_minio
      args  = ["server", "/data", "--console-address", ":9001"]

      security_context {
        allow_privilege_escalation = false
        capabilities {
          drop = ["ALL"]
        }
        run_as_non_root = true
        run_as_user     = 1001
        run_as_group    = 1001
        seccomp_profile {
          type = "RuntimeDefault"
        }
      }

      env {
        name = "MINIO_ROOT_USER"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootUser"
          }
        }
      }
      env {
        name = "MINIO_ROOT_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootPassword"
          }
        }
      }
      port {
        container_port = 9000
      }
      port {
        container_port = 9001
      }
      volume_mount {
        name       = "data"
        mount_path = "/data"
      }
      readiness_probe {
        http_get {
          path = "/minio/health/ready"
          port = 9000
        }
        initial_delay_seconds = 10
        period_seconds        = 5
      }
      liveness_probe {
        http_get {
          path = "/minio/health/live"
          port = 9000
        }
        initial_delay_seconds = 20
        period_seconds        = 10
      }
    }

    # MinIO Init Sidecar Container
    container {
      name  = "minio-init"
      image = "quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z"

      security_context {
        allow_privilege_escalation = false
        capabilities {
          drop = ["ALL"]
        }
        run_as_non_root = true
        run_as_user     = 1001
        run_as_group    = 1001
        seccomp_profile {
          type = "RuntimeDefault"
        }
      }
      env {
        name = "MINIO_ROOT_USER"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootUser"
          }
        }
      }
      env {
        name = "MINIO_ROOT_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootPassword"
          }
        }
      }
      env {
        name = "APP_ACCESS_KEY"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "appAccessKey"
          }
        }
      }
      env {
        name = "APP_SECRET_KEY"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "appSecretKey"
          }
        }
      }
      env {
        name  = "FORCE_RECREATE_USER"
        value = tostring(false)
      }
      command = ["/bin/sh", "-c"]
      args = [<<-EOT
        set -euo pipefail
        MINIO_ENDPOINT="http://localhost:9000"
        echo "[init] Waiting for MinIO to be ready..."
        for i in $(seq 1 60); do
          if mc alias set local "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; then
            if mc ls local >/dev/null 2>&1; then
              echo "[init] MinIO ready on attempt $i"; break
            fi
          fi
          sleep 2
          if [ "$i" = 60 ]; then echo "Failed to connect to MinIO" >&2; exit 1; fi
        done
        
        BUCKET="${var.tag_prefix}-bucket"
        USER="app-user"
        ACCESS_KEY="$APP_ACCESS_KEY"
        SECRET_KEY="$APP_SECRET_KEY"
        
        echo "[init] Creating bucket $BUCKET if it doesn't exist..."
        if ! mc ls local/$BUCKET >/dev/null 2>&1; then 
          mc mb local/$BUCKET
          echo "[init] Bucket $BUCKET created"
        else
          echo "[init] Bucket $BUCKET already exists"
        fi
        
        echo "[init] Setting up user $USER..."
        USER_EXISTS=0; mc admin user info local $USER >/dev/null 2>&1 && USER_EXISTS=1 || true
        if [ "$FORCE_RECREATE_USER" = "true" ] && [ $USER_EXISTS -eq 1 ]; then 
          mc admin user remove local $USER || true
          USER_EXISTS=0
          echo "[init] Removed existing user $USER"
        fi
        if [ $USER_EXISTS -eq 0 ]; then 
          mc admin user add local $ACCESS_KEY $SECRET_KEY
          mc admin policy attach local readwrite --user $ACCESS_KEY
          echo "[init] User $USER created and policy attached"
        else
          echo "[init] User $USER already exists"
        fi
        
        echo "[init] MinIO initialization completed successfully"
        
        # Keep the sidecar running to prevent pod restart
        echo "[init] Keeping sidecar alive..."
        while true; do sleep 30; done
      EOT
      ]
    }
    volume {
      name = "data"
      empty_dir {}
    }
  }


  lifecycle {
    ignore_changes = [spec[0].security_context]
  }
}

# Service
resource "kubernetes_service" "minio" {
  metadata {
    name      = "${var.tag_prefix}-minio"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "minio"
    }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
    }
    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
    type = "LoadBalancer"
  }
  wait_for_load_balancer = false
}

# output "minio_service_name" {
#   value = kubernetes_service.minio.metadata[0].name
# }

# output "minio_endpoint" {
#   value = "${kubernetes_service.minio.metadata[0].name}.${var.namespace}.svc.cluster.local:${kubernetes_service.minio.spec[0].port[0].port}"
# }

output "minio_console_url" {
  value = "http://localhost:${kubernetes_service.minio.spec[0].port[1].port}/"
}

output "minio_user" {
  value = var.minio_user
}

output "minio_password" {
  value = var.minio_password
}