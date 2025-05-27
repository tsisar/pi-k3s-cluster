# Створюємо ServiceAccount для Vault, під яким він буде звертатись до Kubernetes API
resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault-auth"
    namespace = var.namespace
  }
}

# Створюємо Secret типу "service-account-token", який пов'язаний з ServiceAccount vault-auth
# Цей токен буде використовувати Vault для TokenReview запитів
resource "kubernetes_secret" "vault_sa_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault.metadata[0].name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

# Активуємо Kubernetes Auth Backend у Vault
resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Kubernetes authentication for applications"
}

# Налаштовуємо Kubernetes Auth Backend:
# - передаємо Vault токен для перевірки автентичності подів
# - задаємо адресу Kubernetes API
resource "vault_kubernetes_auth_backend_config" "config" {
  backend               = vault_auth_backend.kubernetes.path
  kubernetes_host       = "https://kubernetes.default.svc:443"
  token_reviewer_jwt    = kubernetes_secret.vault_sa_token.data["token"]
  kubernetes_ca_cert    = kubernetes_secret.vault_sa_token.data["ca.crt"]
  disable_iss_validation = true
}

# Створюємо політику в Vault, яка дозволяє читати секрети
resource "vault_policy" "read_secrets" {
  name = "read-secrets"
  policy = file("${path.module}/policies/read-secrets.hcl")
}

# Створюємо ClusterRole, яка дає права робити TokenReview та читати Pods/ServiceAccounts
resource "kubernetes_cluster_role" "vault_token_reviewer" {
  metadata {
    name = "vault-token-reviewer"
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

# Прив'язуємо створену ClusterRole до нашого ServiceAccount
resource "kubernetes_cluster_role_binding" "vault_token_reviewer_binding" {
  metadata {
    name = "vault-token-reviewer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.vault_token_reviewer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault.metadata[0].name
    namespace = var.namespace
  }
}

# Створюємо роль у Vault для додатків:
# - прив'язуємо ServiceAccount до ролі
# - вказуємо політику
# - задаємо TTL токена
resource "vault_kubernetes_auth_backend_role" "app" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "app-role"
  bound_service_account_names      = [kubernetes_service_account.vault.metadata[0].name]
  bound_service_account_namespaces = [var.namespace]
  token_policies                   = [vault_policy.read_secrets.name]
  token_ttl                        = 3600           # токен живе 1 годину
  token_max_ttl                    = 7200           # максимум 2 години після продовження
  token_period                     = 3600           # автоматичне поновлення кожну годину (опціонально)
  audience                         = "vault"        # перевірка audience у токені
}
