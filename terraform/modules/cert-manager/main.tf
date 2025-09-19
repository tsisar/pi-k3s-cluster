variable "app_version" {
  description = "Cert Manager version"
  default     = "v1.17.2"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Install cert-manager using Helm
# Note: cert-manager CRDs are installed via Ansible (playbook 07-setup-crds.yml)
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.app_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set = [
    {
      name  = "installCRDs"
      value = "false"  # CRDs are installed via Ansible
    }
  ]

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}
