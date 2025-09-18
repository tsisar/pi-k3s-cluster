resource "kubernetes_namespace" "demo" {
  metadata {
    name = var.namespace
  }
}

resource "argocd_application" "demo" {
  metadata {
    name      = var.name
    namespace = "argocd"
  }

  spec {
    project = "default"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = var.namespace
    }

    source {
      repo_url        = var.repo_url
      path            = "helm/demo"
      target_revision = var.target_revision

      helm {
        release_name = var.name
        value_files = ["values.yaml"]
        parameter {
          name  = "ingress.host"
          value = var.host
        }
      }
    }

    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
    }
  }
}