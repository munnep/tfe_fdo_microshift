terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.36.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.11.0"
    }
  }
}

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
  server_url = var.acme_server_url
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
