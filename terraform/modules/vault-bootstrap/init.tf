resource "kubernetes_service_account" "vault_sa" {
  metadata {
    name      = "vault-sa"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
}

resource "kubernetes_role" "vault_secret_role" {
  metadata {
    name      = "vault-secret-role"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }
}

resource "kubernetes_role_binding" "vault_secret_binding" {
  metadata {
    name      = "vault-secret-binding"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_sa.metadata[0].name
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.vault_secret_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_validating_webhook_configuration" "vault_webhook" {
  metadata {
    name = "vault-webhook"
  }

  webhook {
    name = "vault-log-pods.k8s.webhook"
    admission_review_versions = ["v1"]
    side_effects = "None"
    failure_policy = "Ignore"
    match_policy = "Equivalent"

    client_config {
      service {
        name = "vault-webhook-service"
        namespace = kubernetes_namespace.vault.metadata[0].name
        path = "/validate"
      }
    }

    rule {
      api_groups = ["*"]
      api_versions = ["*"]
      operations = ["CREATE"]
      resources = ["pods"]
      scope = "Namespaced"
    }
  }
}

resource "kubernetes_config_map" "vault_webhook_script" {
  metadata {
    name      = "vault-webhook-script"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "watch_vault_pods.sh" = file("${path.module}/watch_vault_pods.sh")
  }
}

resource "kubernetes_deployment" "vault_webhook" {
  metadata {
    name      = "vault-webhook"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vault-webhook"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault-webhook"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.vault_sa.metadata[0].name

        volume {
          name = "script-volume"
          config_map {
            name = kubernetes_config_map.vault_webhook_script.metadata[0].name
            default_mode = "0777"
          }
        }

        container {
          name  = "webhook"
          image = "bitnami/kubectl:latest"

          command = ["/bin/sh", "-c"]
          args = ["/scripts/watch_vault_pods.sh"]

          volume_mount {
            name       = "script-volume"
            mount_path = "/scripts"
          }
        }
      }
    }
  }
}
