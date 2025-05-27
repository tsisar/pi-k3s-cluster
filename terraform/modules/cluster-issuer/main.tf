variable "staging" {
    description = "staging"
    type        = bool
    default     = false
}

variable "email" {
    description = "email"
    type        = string
}

locals {
  server = var.staging ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = {
      name = "letsencrypt-issuer"
    }
    spec = {
      acme = {
        server = local.server
        email  = var.email
        privateKeySecretRef = {
          name = "letsencrypt-issuer"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}