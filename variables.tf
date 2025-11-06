# General
variable "dns_zone" {
  description = "The domain used in the URL."
  type        = string
}

variable "dns_subdomain" {
  description = "the subdomain of the url"
  type        = string
}

variable "cert_email" {
  description = "Email address used to obtain ssl certificate."
  type        = string
}

variable "kubectl_config_path" {
  description = "Path to the kube config file."
  type        = string
  default     = "~/.kube/config"
}

variable "kubectl_context" {
  description = "The context to use within the kube config file."
  type        = string
  default     = "microshift"
}

variable "tfe_agent_image" {
  description = "Docker image for the TFE agent ."
  type        = string
  default     = "patrickmunne3/custom-agent-openshift:v1.4"
}


variable "namespace" {
  description = "Kubernetes namespace to deploy resources into."
  type        = string
  default     = "terraform-enterprise"
}

variable "tag_prefix" {
  description = "Prefix for naming Kubernetes resources."
  type        = string
  default     = "tfe"
}

# Cloudflare
variable "cloudflare_account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "cloudflare_api_token" {
  description = "API token for Cloudflare DNS challenge."
  type        = string
}

# Minio
variable "minio_user" {
  description = "Minio username."
  type        = string
}

variable "minio_password" {
  description = "Minio password."
  type        = string
}

variable "minio_access_key" {
  description = "Minio access key."
  type        = string
}

variable "minio_secret_key" {
  description = "Minio secret key."
  type        = string
}

variable "image_minio" {
  description = "Minio docker image."
  type        = string
}

# Postgres
variable "postgres_user" {
  description = "Postgres username."
  type        = string
}

variable "postgres_password" {
  description = "Postgres password."
  type        = string
}

variable "postgres_db" {
  description = "Postgres database name."
  type        = string
}

variable "image_postgres" {
  description = "Postgres docker image."
  type        = string
}

# Redis
variable "image_redis" {
  description = "Redis docker image."
  type        = string
}

# TFE
variable "tfe_encryption_password" {
  description = "Password used to encrypt TFE data."
  type        = string
}

variable "admin_username" {
  description = "Username for the TFE admin account."
  type        = string
}

variable "admin_email" {
  description = "Email address for the TFE admin account."
  type        = string
}

variable "admin_password" {
  description = "Password for the TFE admin account."
  type        = string
}

variable "release_sequence" {
  description = "Release number of the TFE version you wish to install."
  type        = string
}

variable "registry_username" {
  description = "Username to download docker tfe image."
  type        = string
  default     = "terraform"
}

variable "registry_images_url" {
  description = "URL for the images registry to download docker tfe image."
  type        = string
  default     = "images.releases.hashicorp.com"
}

variable "tfe_raw_license" {
  description = "The raw TFE license string"
  type        = string
}

variable "replica_count" {
  description = "Number of replicas (pods)."
  type        = number
  default     = 1
}

