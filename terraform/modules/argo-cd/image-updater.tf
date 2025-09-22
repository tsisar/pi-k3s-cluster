locals {
  image_updater_values_yaml = templatefile("${path.module}/image-updater.values.yaml.tpl", {
    server_addr     = "${var.host}:443"
    server_insecure = var.server_insecure
    grpc_web        = true
    log_level       = "info"

    nexus_api_url     = var.nexus_api_url
    nexus_prefix      = var.nexus_prefix
    argo_namespace    = kubernetes_namespace.argo_cd.metadata[0].name
    nexus_secret_name = kubernetes_secret.nexus_creds.metadata[0].name
  })
}

resource "kubernetes_secret" "nexus_creds" {
  metadata {
    name      = "nexus-creds"
    namespace = kubernetes_namespace.argo_cd.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = var.nexus_username
    password = var.nexus_password
  }
}

resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  namespace  = kubernetes_namespace.argo_cd.metadata[0].name

  values = [local.image_updater_values_yaml]

  set_sensitive = [
    {
      name  = "secret.argocd.username"
      value = local.username
    },
    {
      name  = "secret.argocd.password"
      value = local.password
    }
  ]

  depends_on = [
    helm_release.argo_cd
  ]
}
