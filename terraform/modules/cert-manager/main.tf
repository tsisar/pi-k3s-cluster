variable "app_version" {
  description = "Cert Manager version"
  default     = "v1.17.2"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.app_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}
