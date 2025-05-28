output "hosts" {
  value = local.hosts
}

output "vault" {
  value = module.vault
}

output "stage" {
  value = local.current_stage
}