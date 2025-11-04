# Create a namespace
resource "kubernetes_namespace" "terraform_enterprise" {
  metadata {
    name = var.namespace
  }
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}