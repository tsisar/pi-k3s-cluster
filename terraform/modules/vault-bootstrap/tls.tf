resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vault_cert" {
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault-internal"
    organization = "MyOrg"
  }

  validity_period_hours = 8760
  early_renewal_hours   = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  dns_names = [
    var.host_local,
    var.host_external,
    "vault-internal",
    "vault-0.vault-internal",
    "vault-1.vault-internal",
    "vault-2.vault-internal"
  ]

  ip_addresses = ["127.0.0.1"]
}

resource "kubernetes_secret" "vault_tls" {
  metadata {
    name      = "vault-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "vault.crt" = tls_self_signed_cert.vault_cert.cert_pem
    "vault.key" = tls_private_key.vault.private_key_pem
    "ca.crt"    = tls_self_signed_cert.vault_cert.cert_pem
  }

  type = "Opaque"
}