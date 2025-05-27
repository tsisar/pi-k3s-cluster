resource "vault_mount" "secret" {
  path        = "secret"
  type        = "kv"
  options     = {
    version = "2"
  }
}