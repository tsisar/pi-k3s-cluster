variable "domain_local" {
  description = "Domain"
  type        = string
  default     = "local"
}

variable "domain_external" {
  description = "Domain"
  type        = string
}

variable "email" {
  description = "Email"
  type        = string
  default     = "admin@example.com"
}

variable "mikrotik_username" {
  description = "Mikrotik username"
  type        = string
}

variable "mikrotik_password" {
  description = "Mikrotik password"
  type        = string
}

variable "vault_address" {
  description = "Vault address"
  type        = string
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

variable "dex_git_hub_client_id" {
  description = "Dex GitHub client ID"
  type        = string
}

variable "dex_git_hub_client_secret" {
  description = "Dex GitHub client secret"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Token"
  type        = string
  sensitive   = true
}

variable "rpc_endpoint" {
  description = "RPC endpoint for Starknet"
  type        = string
  default     = "https://rpc.testnet.starknet.io"
}

variable "rpc_ws_endpoint" {
  description = "RPC WebSocket endpoint for Starknet"
  type        = string
  default     = "wss://rpc.testnet.starknet.io/ws"
}

variable "enabled_modules" {
  type = map(bool)
  default = {
    ingress_nginx         = true
    cert_manager          = true
    redis                 = true
    vault                 = true
    cluster_issuer        = true
    vault_config          = true
    monitoring            = true
    argo_cd               = true
    repository_deploy_key = true
    demo                  = true
    indexer               = true
    proxy                 = true
  }
}

variable "hosts" {
  type = map(string)
  default = {
    vault     = "vault.k3s-test.local"
    redis           = "redis.k3s-test.local"
    redis_commander = "redis-commander.k3s-test.local"
    prometheus      = "prometheus.k3s-test.local"
    grafana         = "grafana.k3s-test.local"
    argo            = "argo.k3s-test.local"
    vault_local     = "vault.k3s-test.local"
    vault_external  = "vault.k3s-test.local"
    demo            = "demo.k3s-test.local"
    postgres        = "postgres.k3s-test.local"
    hasura          = "hasura.k3s-test.local"
  }
}