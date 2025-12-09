# Fetch the Cloudflare zone information
data "cloudflare_zones" "main" {
  account = {
    id = var.cloudflare_account_id
  }
}

# Create a Cloudflare Zero Trust Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "tfe_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "${var.tag_prefix}-tunnel-microshift"
  config_src = "local"
}

# Reads the token used to run the tunnel on the server
data "cloudflare_zero_trust_tunnel_cloudflared_token" "tfe_tunnel_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tfe_tunnel.id
}

# Create the DNS record pointing to the tunnel
resource "cloudflare_dns_record" "tunnel_dns" {
  zone_id = data.cloudflare_zones.main.result.0.id
  name    = local.fqdn
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tfe_tunnel.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# Kubernetes deployment for cloudflared tunnel
# Secret containing tunnel information
resource "kubernetes_secret" "tunnel_credentials" {
  metadata {
    name      = "tunnel-credentials"
    namespace = kubernetes_namespace.terraform_enterprise[var.dep_namespace].metadata.0.name
  }

  data = {
    "tunnel-token" = data.cloudflare_zero_trust_tunnel_cloudflared_token.tfe_tunnel_token.token
  }
}

# ConfigMap containing the tunnel configuration
resource "kubernetes_config_map" "tunnel_config" {
  metadata {
    name      = "tunnel-config"
    namespace = kubernetes_namespace.terraform_enterprise[var.dep_namespace].metadata.0.name
  }

  data = {
    "config.yaml" = templatefile("${path.module}/scripts/cloudflare_tunnel_config.yaml", {
      tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tfe_tunnel.id
      fqdn      = local.fqdn
      namespace = kubernetes_namespace.terraform_enterprise[var.namespace].metadata.0.name
    })
  }
}

# Pod for cloudflared
resource "kubernetes_pod" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.terraform_enterprise[var.dep_namespace].metadata.0.name
    labels = {
      app = "cloudflared"
    }
    annotations = {
      "openshift.io/scc" = "anyuid"
    }
  }

  spec {
    security_context {
      run_as_non_root = true
      run_as_user     = 65532
      seccomp_profile {
        type = "RuntimeDefault"
      }
    }

    container {
      name  = "cloudflared"
      image = "docker.io/cloudflare/cloudflared:latest"

      security_context {
        allow_privilege_escalation = false
        capabilities {
          drop = ["ALL"]
        }
        run_as_non_root = true
        run_as_user     = 65532
        seccomp_profile {
          type = "RuntimeDefault"
        }
      }

      args = [
        "tunnel",
        "--edge-ip-version",
        "4",
        "--protocol",
        "http2",
        "--config",
        "/etc/cloudflared/config.yaml",
        "run",
        "--token",
        "$(TUNNEL_TOKEN)"
      ]

      env {
        name = "TUNNEL_TOKEN"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.tunnel_credentials.metadata[0].name
            key  = "tunnel-token"
          }
        }
      }

      volume_mount {
        name       = "config"
        mount_path = "/etc/cloudflared"
        read_only  = true
      }
    }

    volume {
      name = "config"
      config_map {
        name = kubernetes_config_map.tunnel_config.metadata[0].name
      }
    }
  }

  lifecycle {
    ignore_changes = [spec[0].security_context, metadata[0].annotations]
    replace_triggered_by = [
      kubernetes_config_map.tunnel_config
    ]
  }
}

output "cloudflare_login_command" {
  value = "cloudflared login"
}

output "cloudflare_list_tunnels_command" {
  value = "cloudflared tunnel list"

}

output "cloudflare_delete_tunnel_command" {
  #value = "cloudflared tunnel delete ${cloudflare_zero_trust_tunnel_cloudflared.tfe_tunnel.id}"
  value = "cloudflared tunnel delete ${cloudflare_zero_trust_tunnel_cloudflared.tfe_tunnel.name}"
}

