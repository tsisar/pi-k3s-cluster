locals {
  current_stage = tonumber(data.external.current_stage.result.stage)
}

data "external" "current_stage" {
  program = ["bash", "${path.module}/scripts/get_stage.sh"]
}

# ================= Mikrotik ==================

resource "mikrotik_dns_record" "record" {
  for_each = var.hosts

  name    = each.value
  address = "192.168.88.30"
  ttl     = 300
}

# ================= Stage-1 ====================

module "ingress_nginx" {
  source   = "./modules/ingress-nginx"
  for_each = var.enabled_modules.ingress_nginx ? { "enabled" = {} } : {}
}

module "cert_manager" {
  source   = "./modules/cert-manager"
  for_each = var.enabled_modules.cert_manager ? { "enabled" = {} } : {}
}

module "redis" {
  source         = "./modules/redis"
  for_each       = var.enabled_modules.redis ? { "enabled" = {} } : {}
  redis_host     = var.hosts.redis
  commander_host = var.hosts.redis_commander

  depends_on = [
    mikrotik_dns_record.record
  ]
}

module "vault" {
  source        = "./modules/vault-bootstrap"
  for_each      = var.enabled_modules.vault ? { "enabled" = {} } : {}
  host_local    = var.hosts.vault_local
  host_external = var.hosts.vault_external

  depends_on = [
    mikrotik_dns_record.record
  ]
}

resource "null_resource" "bump_stage_to_2" {
  provisioner "local-exec" {
    command = "jq '.stage = \"2\"' ${path.module}/scripts/stage.json > ${path.module}/scripts/stage.tmp && mv ${path.module}/scripts/stage.tmp ${path.module}/scripts/stage.json"
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    module.ingress_nginx,
    module.cert_manager,
    module.redis,
    module.vault
  ]
}

# ================= Stage-2 ====================

module "cluster_issuer" {
  source   = "./modules/cluster-issuer"
  for_each = var.enabled_modules.cluster_issuer ? { "enabled" = {} } : {}
  email    = var.email
}

module "vault_config" {
  source        = "./modules/vault-config"
  for_each      = var.enabled_modules.vault_config ? { "enabled" = {} } : {}
  namespace     = module.vault["enabled"].namespace
  host_local    = var.hosts.vault_local
  host_external = var.hosts.vault_external

  depends_on = [
    module.cluster_issuer,
    module.vault
  ]
}

module "monitoring" {
  source          = "./modules/monitoring"
  for_each        = var.enabled_modules.monitoring ? { "enabled" = {} } : {}
  grafana_host    = var.hosts.grafana
  prometheus_host = var.hosts.prometheus

  depends_on = [
    module.vault_config
  ]
}

module "argo_cd" {
  source                    = "./modules/argo-cd"
  for_each                  = var.enabled_modules.argo_cd ? { "enabled" = {} } : {}
  dex_git_hub_client_id     = var.dex_git_hub_client_id
  dex_git_hub_client_secret = var.dex_git_hub_client_secret
  host                      = var.hosts.argo
  email                     = var.email

  depends_on = [
    module.vault_config
  ]
}

# Setting up Deploy Key in GitHub repository and connecting it to ArgoCD
module "infra" {
  source   = "./modules/infra-repository"
  for_each = var.enabled_modules.repository_deploy_key ? { "enabled" = {} } : {}
}

# Demo Module
module "demo" {
  source     = "./modules/demo"
  for_each   = var.enabled_modules.demo ? { "enabled" = {} } : {}
  host       = var.hosts.demo
  repository = module.infra["enabled"].repository

  depends_on = [
    module.argo_cd,
    module.infra
  ]
}

# Indexer Module
module "indexer" {
  source          = "./modules/indexer"
  for_each        = var.enabled_modules.indexer ? { "enabled" = {} } : {}
  name            = "starknet"
  namespace       = "indexer"
  repository      = "https://github.com/tsisar/starknet-indexer.git"
  branch          = "dev"
  rpc_endpoint    = var.rpc_endpoint
  rpc_ws_endpoint = var.rpc_ws_endpoint
  host            = var.hosts.indexer

  depends_on = [
    module.argo_cd,
    module.infra
  ]
}