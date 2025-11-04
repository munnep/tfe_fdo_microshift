# Create a namespace
resource "kubernetes_namespace" "terraform_enterprise" {
  metadata {
    name = var.namespace
  }
}