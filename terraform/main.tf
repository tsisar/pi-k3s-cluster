# ================= Mikrotik ==================

resource "routeros_ip_dns_record" "name_record" {
  for_each = var.hosts

  name    = each.value
  address = "192.168.88.30"
  type    = "A"
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

# ================= Stage-2 ====================

module "cluster_issuer" {
  source   = "./modules/cluster-issuer"
  for_each = var.enabled_modules.cluster_issuer ? { "enabled" = {} } : {}
  email    = var.email
}

module "monitoring" {
  source          = "./modules/monitoring"
  for_each        = var.enabled_modules.monitoring ? { "enabled" = {} } : {}
  grafana_host    = var.hosts.grafana
  prometheus_host = var.hosts.prometheus
  
  # InfluxDB configuration
  influxdb_host     = "192.168.88.30"
  influxdb_port     = 8086
  influxdb_org      = "k3s-cluster"
  influxdb_bucket   = "telegraf"
  influxdb_token    = var.influxdb_token
  
  # Smartctl Exporter configuration
  smartctl_exporter_enabled   = true
  smartctl_exporter_image     = "prometheuscommunity/smartctl-exporter:latest"
  smartctl_exporter_interval  = "60s"
  smartctl_exporter_rescan    = "10m"
}

module "argo_cd" {
  source                    = "./modules/argo-cd"
  for_each                  = var.enabled_modules.argo_cd ? { "enabled" = {} } : {}
  dex_git_hub_client_id     = var.dex_git_hub_client_id
  dex_git_hub_client_secret = var.dex_git_hub_client_secret
  host                      = var.hosts.argo
  email                     = var.email
}

module "keycloak" {
  source    = "./modules/keycloak"
  for_each  = var.enabled_modules.keycloak ? { "enabled" = {} } : {}
  host      = var.hosts.keycloak
  namespace = "keycloak"
}