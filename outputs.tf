output "postgres_port_forward_command" {
  value = "kubectl port-forward -n ${var.namespace} svc/${kubernetes_service_v1.postgres.metadata[0].name} ${kubernetes_service_v1.postgres.spec[0].port[0].port}:${kubernetes_service_v1.postgres.spec[0].port[0].port}"
}

output "minio_port_forward_command_api" {
  value = "kubectl port-forward -n ${var.namespace} svc/${kubernetes_service_v1.minio.metadata[0].name} ${kubernetes_service_v1.minio.spec[0].port[0].port}:${kubernetes_service_v1.minio.spec[0].port[0].port}"
}

output "minio_port_forward_command_console" {
  value = "kubectl port-forward -n ${var.namespace} svc/${kubernetes_service_v1.minio.metadata[0].name} ${kubernetes_service_v1.minio.spec[0].port[1].port}:${kubernetes_service_v1.minio.spec[0].port[1].port}"
}

