
locals {
  values_yaml_content = templatefile("${path.module}/values.yaml.tpl", {
    grafana_password = "prom-operator",
    influxdb_host = var.influxdb_host,
    influxdb_port = var.influxdb_port,
    influxdb_org = var.influxdb_org,
    influxdb_bucket = var.influxdb_bucket,
    influxdb_token = var.influxdb_token,
  })
}

# resource "random_password" "grafana" {
#   length  = 16
#   special = false
# }

# resource "vault_generic_secret" "grafana_password" {
#   path = "secret/grafana"
#
#   data_json = jsonencode({
#     password = random_password.grafana.result
#   })
# }

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "72.6.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [local.values_yaml_content]
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "node-exporter-dashboard.json" = file("${path.module}/dashboards/node-exporter-dashboard.json")
    "telegraf_linux_ready.json"    = file("${path.module}/dashboards/telegraf_linux_ready.json")
    "smartctl_exporter_fixed.json" = file("${path.module}/dashboards/smartctl_exporter_fixed.json")
  }
}

resource "kubernetes_ingress_v1" "prometheus_internal" {
  metadata {
    name      = "prometheus-ingress-internal"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.prometheus_host
      http {
        path {
          backend {
            service {
              name = "kube-prometheus-stack-prometheus"
              port {
                number = 9090
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "grafana_internal" {
  metadata {
    name      = "grafana-ingress-internal"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.grafana_host
      http {
        path {
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}