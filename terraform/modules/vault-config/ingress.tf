
resource "kubernetes_ingress_v1" "vault_local" {
  metadata {
    name      = "vault-ingress-local"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.host_local
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "vault" {
  metadata {
    name      = "vault-ingress"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/instance" = "vault"
    }
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-issuer"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.host_external
      http {
        path {
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts = [var.host_external]
      secret_name = "vault-tls-letsencrypt"
    }
  }
}
