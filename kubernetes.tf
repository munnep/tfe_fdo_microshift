# Create a namespace
resource "kubernetes_namespace" "terraform_enterprise" {

  for_each = toset([var.namespace, var.dep_namespace])

  metadata {
    name = each.value
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }

}
