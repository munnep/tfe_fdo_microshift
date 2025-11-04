# General outputs (container specific outputs are in their respective files)

output "minikube_tunnel" {
  value = "sudo minikube tunnel --profile=tfe"
}

output "minikube_delete_cluster" {
  value = "minikube delete --profile=tfe"  
}