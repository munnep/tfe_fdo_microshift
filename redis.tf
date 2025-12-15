resource "kubernetes_pod_v1" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = kubernetes_namespace_v1.terraform_enterprise[var.dep_namespace].metadata.0.name
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

resource "kubernetes_service_v1" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = kubernetes_namespace_v1.terraform_enterprise[var.dep_namespace].metadata.0.name
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

