output "hosts" {
  value = var.hosts
}

output "vault" {
  value = module.vault
}

output "redis" {
  value = module.redis
}

output "stage" {
  value = local.current_stage
}