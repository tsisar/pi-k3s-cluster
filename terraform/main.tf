locals {
  enabled_modules = {
    ingress_nginx  = var.stage >= 1
    cert_manager   = var.stage >= 1
    redis          = var.stage >= 1
    vault          = var.stage >= 1
    cluster_issuer = var.stage >= 2
    vault_config   = var.stage >= 2
    monitoring     = var.stage >= 2
    argo_cd        = var.stage >= 2
  }

  hosts = {
    vault_local     = "vault.${var.domain_local}"
    vault_external  = "vault.${var.domain_external}"
    redis           = "redis.${var.domain_local}"
    redis_commander = "redis-commander.${var.domain_local}"
    prometheus      = "prometheus.${var.domain_local}"
    grafana         = "grafana.${var.domain_local}"
    argo            = "argo.${var.domain_external}"
    vault_local     = "vault.${var.domain_local}"
    vault_external  = "vault.${var.domain_external}"
  }

}

# ================= Mikrotik ==================

resource "mikrotik_dns_record" "record" {
  for_each = local.hosts

  name    = each.value
  address = "192.168.88.30"
  ttl     = 300
}

# ================= Stage-1 ====================

module "ingress_nginx" {
  source   = "./modules/ingress-nginx"
  for_each = local.enabled_modules.ingress_nginx ? { "enabled" = {} } : {}
}

module "cert_manager" {
  source   = "./modules/cert-manager"
  for_each = local.enabled_modules.cert_manager ? { "enabled" = {} } : {}
}

module "redis" {
  source         = "./modules/redis"
  for_each       = local.enabled_modules.redis ? { "enabled" = {} } : {}
  redis_host     = local.hosts.redis
  commander_host = local.hosts.redis_commander

  depends_on = [
    mikrotik_dns_record.record
  ]
}

module "vault" {
  source        = "./modules/vault-bootstrap"
  for_each      = local.enabled_modules.vault ? { "enabled" = {} } : {}
  host_local    = local.hosts.vault_local
  host_external = local.hosts.vault_external

  depends_on = [
    mikrotik_dns_record.record
  ]
}

# ================= Stage-2 ====================

module "cluster_issuer" {
  source   = "./modules/cluster-issuer"
  for_each = local.enabled_modules.cert_manager ? { "enabled" = {} } : {}
  email    = var.email
}

module "vault_config" {
  source        = "./modules/vault-config"
  for_each      = local.enabled_modules.vault_config ? { "enabled" = {} } : {}
  namespace     = module.vault["enabled"].namespace
  host_local    = local.hosts.vault_local
  host_external = local.hosts.vault_external

  depends_on = [
    mikrotik_dns_record.record,
    module.cluster_issuer["enabled"],
    module.vault["enabled"]
  ]
}

module "monitoring" {
  source          = "./modules/monitoring"
  for_each        = local.enabled_modules.monitoring ? { "enabled" = {} } : {}
  grafana_host    = local.hosts.grafana
  prometheus_host = local.hosts.prometheus

  depends_on = [
    module.vault_config["enabled"]
  ]
}

module "argo_cd" {
  source                    = "./modules/argo-cd"
  for_each                  = local.enabled_modules.argo_cd ? { "enabled" = {} } : {}
  dex_git_hub_client_id     = var.dex_git_hub_client_id
  dex_git_hub_client_secret = var.dex_git_hub_client_secret
  host                      = local.hosts.argo
  email                     = var.email

  depends_on = [
    module.vault_config["enabled"]
  ]
}
