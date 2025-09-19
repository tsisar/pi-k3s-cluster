output "helm_release_status" { value = helm_release.eg.status }

output "namespace" {
  value       = kubernetes_namespace.eg.metadata[0].name
  description = "Namespace where Envoy Gateway is deployed"
}

output "helm_release" {
  value       = helm_release.eg
  description = "The Helm release for Envoy Gateway"
}

output "gateway_namespace" {
  description = "Namespace where Envoy Gateway is deployed"
  value       = kubernetes_namespace.eg.metadata[0].name
}

output "gateway_class_name" {
  description = "Envoy Gateway class name"
  value       = var.gateway_class_name
}

output "gateway_name" {
  description = "Envoy Gateway name"
  value       = var.gateway_name
}
