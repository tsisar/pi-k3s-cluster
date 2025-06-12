variable "postgres_db" {
  description = "PostgreSQL database"
  type        = string
  default     = "indexer"
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
  default     = "indexer"
}

resource "argocd_application" "postgres" {
  metadata {
    name      = "${var.name}-postgres"
    namespace = "argocd"
    labels = {
      app     = "${var.name}-postgres"
      type    = var.type
      project = var.project
      network = var.network
    }
  }

  cascade = true

  spec {
    project = "default"

    destination {
      name      = "in-cluster"
      namespace = kubernetes_namespace.indexer.metadata[0].name
    }

    source {
      repo_url        = "git@github.com:desync-labs/splyce-infrastructure.git"
      path            = "k8s/postgres"
      target_revision = var.branch

      helm {
        value_files = ["values.yaml"]

        parameter {
          name  = "env.postgres_db"
          value = var.postgres_db
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

  depends_on = [
    kubernetes_namespace.indexer
  ]
}

resource "random_password" "postgres_password" {
  length  = 12
  special = false
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.indexer.metadata[0].name

    labels = {
      owner                        = "desynclabs"
      "app.kubernetes.io/instance" = kubernetes_namespace.indexer.metadata[0].name
      "app.kubernetes.io/name"     = "${var.name}-postgres"
    }
  }

  type = "Opaque"

  data = {
    user     = var.postgres_user
    password = random_password.postgres_password.result
  }
}

output "postgres_user" {
  value = var.postgres_user
}

output "postgres_password" {
  value = random_password.postgres_password.result
}