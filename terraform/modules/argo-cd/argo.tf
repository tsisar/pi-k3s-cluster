locals {
  values_yaml_content = templatefile("${path.module}/argo.values.yaml.tpl", {
    server_insecure = var.server_insecure,
    host            = "https://${var.host}",
  })
  username = "admin"
  password = "admin"
}

# resource "random_password" "argo_cd" {
#   length  = 12
#   special = true
# }
#
# resource "vault_generic_secret" "argo_cd" {
#   path = "secret/argo_cd"
#
#   data_json = jsonencode({
#     password = random_password.argo_cd.result
#   })
# }

# Create argo-cd namespace
resource "kubernetes_namespace" "argo_cd" {
  metadata {
    name = "argocd"
  }
}

# Install ArgoCD using Helm
# Note: ArgoCD CRDs are installed via Ansible (playbook 07-setup-crds.yml)
resource "helm_release" "argo_cd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  # Use dynamically generated values.yaml file
  values = [local.values_yaml_content]

  set_sensitive = [
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = bcrypt(local.password)
    }
  ]
  lifecycle {
    ignore_changes = [set_sensitive]
  }

  depends_on = [
    kubernetes_namespace.argo_cd
  ]
}

# Ingress resource for Argo CD with Let's Encrypt certificate
resource "kubernetes_ingress_v1" "argo_cd" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/instance" = "argocd"
    }
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.host
      http {
        path {
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts       = [var.host]
      secret_name = "argocd-tls"
    }
  }

  depends_on = [
    helm_release.argo_cd
  ]
}

output "host" {
  value = var.host
}

output "username" {
  value = local.username
}

output "password" {
  value     = local.password
  sensitive = true
}
