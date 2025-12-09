resource "kubernetes_secret" "terraform-enterprise" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace.terraform_enterprise[var.namespace].metadata.0.name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.registry_images_url) = {
          "username" = var.registry_username
          "password" = var.tfe_raw_license
          "auth"     = base64encode("${var.registry_username}:${var.tfe_raw_license}")
        }
      }
    })
  }
}

resource "helm_release" "tfe" {
  name            = "${var.tag_prefix}-tfe"
  repository      = "https://helm.releases.hashicorp.com"
  chart           = "terraform-enterprise"
  namespace       = kubernetes_namespace.terraform_enterprise[var.namespace].metadata.0.name
  version         = "1.6.5"
  cleanup_on_fail = true
  timeout         = var.helm_timeout

  values = [
    templatefile("${path.module}/overrides.yaml", {
      tag_prefix          = var.tag_prefix
      replica_count       = var.replica_count
      enc_password        = var.tfe_encryption_password
      pg_dbname           = kubernetes_secret.postgres.data.POSTGRES_DB
      pg_user             = kubernetes_secret.postgres.data.POSTGRES_USER
      pg_password         = kubernetes_secret.postgres.data.POSTGRES_PASSWORD
      pg_address          = "${kubernetes_service.postgres.metadata[0].name}.${var.dep_namespace}:${kubernetes_service.postgres.spec[0].port[0].port}"
      fqdn                = local.fqdn
      s3_bucket           = "${var.tag_prefix}-bucket"
      s3_bucket_key       = kubernetes_secret.minio_root.data.appAccessKey
      s3_bucket_secret    = kubernetes_secret.minio_root.data.appSecretKey
      s3_endpoint         = "http://${kubernetes_service.minio.metadata[0].name}.${var.dep_namespace}:${kubernetes_service.minio.spec[0].port[0].port}"
      cert_data           = base64encode("${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}")
      key_data            = base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))
      ca_cert_data        = base64encode("${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}")
      redis_host          = "${var.tag_prefix}-redis.${var.dep_namespace}"
      redis_port          = "6379"
      tfe_license         = var.tfe_raw_license
      tfe_release         = var.release_sequence
      registry_images_url = var.registry_images_url
      tfe_agent_image     = var.tfe_agent_image
    })
  ]
}

output "tfe_execute_script_to_create_user_admin" {
  value = "./scripts/configure_tfe.sh ${local.fqdn} ${var.admin_email} ${var.admin_username} ${var.admin_password}"
}

output "tfe_url" {
  value = "https://${local.fqdn}"
}
