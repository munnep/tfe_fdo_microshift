terraform {
  required_providers {
    # minikube = {
    #   source = "scott-the-programmer/minikube"
    #   version = "0.5.3"
    # }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.36.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.11.0"
    }
  }
}

# minikube provider is not working, so commenting it out for now
# provider "minikube" {
#   kubernetes_version = "v1.34.0"
# }

provider "kubernetes" {
  config_path    = var.kubectl_config_path
  config_context = var.kubectl_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubectl_config_path
    config_context = var.kubectl_context
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}