# HashiCorp Vault з auto unseal без KMS і transit secrets engine

> Піднімаємо Vault у локальному кластері Kubernetes, з авторозпечатуванням без KMS і без transit secrets engine. Пісочниця на локальному кластері, кохфе — погнали!

> **Примітка**: Цей документ описує ручне налаштування Vault. Для автоматизованого розгортання використовуйте [Terraform модулі](/doc/ansible.md).

---

## Навіщо мені це?

Коли в тебе Vault живе в локальному кластері, який подорожує разом з тобою, інколи запускається на столі без інтернету, використання auto unseal KMS або іншим Vault стає неможливим. Щоразу ручками вводити ключ? Нє, дякую.
Чому не dev режим, його ж не потрібно розпечатувати? Так... Але в dev режимі Vault не зберігає дані між перезапусками, тому це не наш варіант.
Ок, тоді прод, з одним unseal ключем? Здається не складно його ввести. Також не варінт, оскільки в мене 3 репліки, а Vault має всім відому проблему коли через веб морду розблоковує лише один под.
Ок, тоді один ключ і один вузол? Ні, оскільки це створює труднощі при відключені чи замінні фізичної ноди в кластері. Так, так таке можливо, в мен ж пісочниця. ;-)
Отже по сховищу на кожен вузол Kubernetes кластеру, з автоматичним розпечатуванням. 

Я буду давати код на HCL, але ви можете адаптувати його під себе.

---

## Що ми робимо?
- Піднімаємо Vault у Kubernetes
- Налаштовуємо auto unseal

І все це — усе просто (або ні).

---

## Step-by-step...

### 1. Namespace: нехай буде порядок

```hcl
resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}
```

Чистенький namespace — це тобі не просто красиво, це зручно.

---

### 2. TLS: так, це потрібно, навіть в пісочниці

Перед розгортанням Vault необхідно створити самопідписані TLS сертифікати:

```hcl
resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vault_cert" {
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name  = "vault-internal"
    organization = "MyOrg"
  }

  validity_period_hours = 8760
  early_renewal_hours   = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  dns_names = [
    "vault.${var.domain_local}",
    "vault-internal",
    "vault-0.vault-internal",
    "vault-1.vault-internal",
    "vault-2.vault-internal"
  ]

  ip_addresses = ["127.0.0.1"]
}

resource "kubernetes_secret" "vault_tls" {
  metadata {
    name      = "vault-tls"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "vault.crt" = tls_self_signed_cert.vault_cert.cert_pem
    "vault.key" = tls_private_key.vault.private_key_pem
    "ca.crt"    = tls_self_signed_cert.vault_cert.cert_pem
  }

  type = "Opaque"
}
```

**Що тут відбувається?**
- Створюється новий приватний ключ RSA 2048 біт для Vault. Він буде використовуватися для підписування сертифікату.
- На базі приватного ключа створюється самопідписаний сертифікат (vault.crt). Він буде використовуватися Vault для шифрування трафіку (TLS/HTTPS) всередині кластера. У мене 3 вузли, тому я вказую в DNS-іменах всі три. `vault-internal` - ім'я сервісу, а `vault` - ім'я хоста яке буде використовуватися для доступу до веб-інтерфейсу Vault.
- Створюється секрет vault-tls, який містить: приватний ключ (vault.key), сертифікат (vault.crt), копію сертифіката як ca.crt (щоб Vault міг довіряти сам собі). Без ca.crt Vault буде вважати свій же TLS сертифікат “недовіреним” і відповідно "продакшену" не може бути. Цей секрет потім монтується в поди Vault для використання в HTTPS-з’єднаннях.

---
### 3. Vault з Helm-у

Я використовую Helm для розгортання Vault. Це зручно, швидко і не вимагає багато зусиль.
Приклад конфігурації лежить в `values.yaml` файлі. В ній я вказую, що Vault буде використовувати Raft як сховище даних, а також налаштовую TLS.

```hcl
resource "helm_release" "vault" {
  name       = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "v0.29.1"

  values = [
    file("${path.module}/values.yaml")
  ]
}
```

Ingress? Так, один локальний, один зовнішній. В зовнішньому я використовую cluster-issuer для автоматичного отримання сертифікатів від Let's Encrypt.

```hcl
resource "kubernetes_ingress_v1" "vault_lan" { ... }
resource "kubernetes_ingress_v1" "vault" { ... }
```
---

### 4. Авто unseal

Думаю це найцікавіша частина - на цьому етапі розпечатуємо Vault. 

#### ServiceAccount + права:

**ServiceAccount для вебхука.**
Створюється сервісний акаунт vault-sa, під яким буде працювати webhook-под. Дозволяє йому ідентифікуватися в кластері.
```hcl
resource "kubernetes_service_account" "vault_sa" {
  metadata {
    name      = "vault-sa"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }
}
```

**Role для доступу до Kubernetes ресурсів.**
Дає права:
- створювати, отримувати і змінювати secrets,
- переглядати і моніторити pods та events,
- створювати сесію exec в подах.
Ці права потрібні для роботи вебхука, який спостерігає за подами.
```hcl
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
```

**Прив’язка Role до ServiceAccount.**
Дозволяє сервісному акаунту vault-sa користуватися правами, визначеними в vault-secret-role.
```hcl
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
```

**Конфігурація Validating Webhook.**
Реєструє webhook, який буде перехоплювати запити на створення подів (CREATE pods) і відправляти їх на перевірку через HTTP-запит на сервіс vault-webhook-service.
```hcl
resource "kubernetes_config_map" "vault_webhook_script" {
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
}
```

**ConfigMap зі скриптом.**
Створює ConfigMap з Bash-скриптом watch_vault_pods.sh, щоб потім змонтувати його в контейнер вебхука.
```hcl
resource "kubernetes_config_map" "vault_webhook_script" {
  metadata {
    name      = "vault-webhook-script"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    "watch_vault_pods.sh" = file("${path.module}/watch_vault_pods.sh")
  }
}
```

**Деплоймент для запуску вебхука.**
Створює под, який:
- використовує vault-sa для доступу до API,
- монтує скрипт із ConfigMap,
- запускає watch_vault_pods.sh всередині контейнера на основі образу bitnami/kubectl.
```hcl
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
```

> Отже, під час створення нового пода в namespace скрипт через webhook перехоплює подію і може виконувати якісь дії, у нашому випадку unseal Vault.

#### А ось і сам скрипт:
```bash
#!/bin/bash

NAMESPACE="vault"
SECRET_NAME="vault-keys"
VAULT_ADDR="https://127.0.0.1:8200"

log() {
  echo "[INFO] $1"
}

log_warn() {
  echo "[WARNING] $1"
}

log_error() {
  echo "[ERROR] $1"
}

get_unseal_key() {
  kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.unseal-key}" 2>/dev/null | base64 --decode
}

store_keys() {
  local unseal_key="$1"
  local root_token="$2"
  kubectl create secret generic "$SECRET_NAME" \
    --from-literal=unseal-key="$unseal_key" \
    --from-literal=root-token="$root_token" \
    --namespace="$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

unseal_vault() {
  local pod="$1"
  local key="$2"
  kubectl exec -n "$NAMESPACE" "$pod" -- env VAULT_ADDR=$VAULT_ADDR vault operator unseal "$key"
  log "Vault pod $pod successfully unsealed."
}

init_vault() {
  local pod="$1"
  log_warn "Secret $SECRET_NAME not found. Initializing Vault on pod: $pod..."

  local init_output
  init_output=$(kubectl exec -n "$NAMESPACE" "$pod" -- env VAULT_ADDR=$VAULT_ADDR vault operator init -key-shares=1 -key-threshold=1)

  local unseal_key
  unseal_key=$(echo "$init_output" | grep 'Unseal Key' | awk '{print $NF}')
  local root_token
  root_token=$(echo "$init_output" | grep 'Initial Root Token' | awk '{print $NF}')

  if [[ -z "$unseal_key" || -z "$root_token" ]]; then
    log_error "Failed to parse unseal key or root token!"
    return 1
  fi

  store_keys "$unseal_key" "$root_token"
  log "Vault has been successfully initialized on pod: $pod."
  unseal_vault "$pod" "$unseal_key"
}

process_pod() {
  local pod="$1"
  log "Processing pod: $pod"

  if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    log "Secret $SECRET_NAME found. Unsealing Vault pod: $pod..."

    local key
    key=$(get_unseal_key)
    if [[ -z "$key" ]]; then
      log_error "Unseal Key not found in Kubernetes Secret!"
      return
    fi

    unseal_vault "$pod" "$key"
  else
    init_vault "$pod"
  fi
}

initial_check() {
  log "Running initial Vault pod check..."

  kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | \
    grep '^vault-[0-9]\+$' | while read -r pod; do
      process_pod "$pod"
    done
}

watch_for_events() {
  log "Watching for Vault pod events in namespace: $NAMESPACE..."

  kubectl get events -n "$NAMESPACE" --watch-only -o json | jq --unbuffered -r '
    .involvedObject.kind as $kind |
    .involvedObject.name as $pod_name |
    .reason as $event_type |
    if $kind == "Pod" then "\($event_type) \($pod_name)" else empty end
  ' | while read -r event pod; do
    if [[ "$pod" =~ ^vault-[0-9]+$ ]] && [[ "$event" == "Started" ]]; then
      log "Detected started Vault pod: $pod. Waiting 60 seconds..."
      sleep 60
      process_pod "$pod"
    fi
  done
}

# === Start ===
initial_check
watch_for_events
```

> Bash-шаманство? Та нє, просто automation with a pinch of paranoia.

---

## Production? Ні. Трохи збочення? Ну так... Зручно? Дуже.

Це рішення НЕ для продакшену. Але для локальної розробки, навчання, демо — **просто ідеально**. 

---

## Дякую за увагу. І так, не забудь створити backup ключів.

Бо наступного разу твій Vault може вже не відкритися. І не кажи, що я не попереджав :)

