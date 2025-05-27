data "kubernetes_secret" "vault_keys" {
  metadata {
    name      = "vault-keys"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
}

locals {
  root_token = try(nonsensitive(data.kubernetes_secret.vault_keys.data["root-token"]), "")
}

output "host_local" {
  value = var.host_local
}

output "host_external" {
  value = var.host_external
}

output "root_token" {
  value = local.root_token
}

output "namespace" {
  value = kubernetes_namespace.vault.metadata[0].name
}