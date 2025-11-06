output "postgres_port_forward_command" {
  value = "kubectl port-forward -n ${var.namespace} svc/${kubernetes_service.postgres.metadata[0].name} ${kubernetes_service.postgres.spec[0].port[0].port}:${kubernetes_service.postgres.spec[0].port[0].port}"
}

output "minio_port_forward_command" {
  value = "kubectl port-forward -n ${var.namespace} svc/${kubernetes_service.minio.metadata[0].name} ${kubernetes_service.minio.spec[0].port[1].port}:${kubernetes_service.minio.spec[0].port[1].port}"
}