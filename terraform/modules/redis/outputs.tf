output "redis_service_endpoint" {
  value = "${kubernetes_service.redis.metadata[0].name}.${kubernetes_service.redis.metadata[0].namespace}:${kubernetes_service.redis.spec[0].port[0].port}"
}

output "redis_service_host" {
  value = "${kubernetes_service.redis.metadata[0].name}.${kubernetes_service.redis.metadata[0].namespace}"
}

output "redis_service_port" {
  value = kubernetes_service.redis.spec[0].port[0].port
}

output "redis_endpoint" {
  value = "${var.redis_host}:${kubernetes_service.redis_nodeport.spec[0].port[0].node_port}"
}

output "redis_nodeport" {
  value = kubernetes_service.redis_nodeport.spec[0].port[0].node_port
}