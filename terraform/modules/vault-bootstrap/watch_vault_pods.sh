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