resource "kubernetes_pod" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = var.namespace
    labels    = { app = "redis" }
    annotations = {
      "openshift.io/scc" = "nonroot-v2"
    }
  }
  spec {
    security_context {
      run_as_non_root = true
      run_as_user     = 999
      run_as_group    = 999
      seccomp_profile {
        type = "RuntimeDefault"
      }
    }

    container {
      name  = "redis"
      image = var.image_redis
      args  = ["redis-server", "--save", "", "--appendonly", "no"]

      security_context {
        allow_privilege_escalation = false
        capabilities {
          drop = ["ALL"]
        }
        run_as_non_root = true
        run_as_user     = 999
        run_as_group    = 999
        seccomp_profile {
          type = "RuntimeDefault"
        }
      }

      port { container_port = 6379 }

      readiness_probe {
        exec { command = ["/bin/sh", "-c", "redis-cli ping | grep PONG"] }
        initial_delay_seconds = 5
        period_seconds        = 5
      }
      liveness_probe {
        exec { command = ["/bin/sh", "-c", "redis-cli ping | grep PONG"] }
        initial_delay_seconds = 20
        period_seconds        = 10
      }

      resources {}

      volume_mount {
        name       = "redis-data"
        mount_path = "/data"
      }
    }
    volume {
      name = "redis-data"
      empty_dir {}
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].security_context,
      metadata[0].annotations["security.openshift.io/validated-scc-subject-type"],
    ]
  }

}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = var.namespace
  }
  spec {
    selector = { app = "redis" }
    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
    }
    type = "LoadBalancer"
  }
  wait_for_load_balancer = false
}

# output "redis_service_name" {
#   value = kubernetes_service.redis.metadata[0].name
# }

# output "redis_endpoint" {
#   value = "${kubernetes_service.redis.metadata[0].name}.${var.namespace}.svc.cluster.local:${kubernetes_service.redis.spec[0].port[0].port}"
# }
