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
      repo_url        = "https://github.com/Tsisar/pi-k3s-cluster.git"
      path            = "helm/demo"
      target_revision = "training"

      helm {
        release_name = var.name
        value_files  = ["values.yaml"]
        values = yamlencode({
          replicaCount = 1
          ingress = {
            host = var.host
          }
        })
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