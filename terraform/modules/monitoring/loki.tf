########################################
# loki.tf — Helm via templated values
########################################

variable "loki_chart_version" {
  description = "Grafana Loki chart version"
  type        = string
  default     = "6.40.0"
}

variable "promtail_chart_version" {
  description = "Grafana Promtail chart version"
  type        = string
  default     = "6.17.0"
}

variable "loki_retention_days" {
  description = "Retention in days for logs"
  type        = number
  default     = 7
}

variable "loki_persistence_enabled" {
  type    = bool
  default = true
}

variable "loki_storage_size" {
  type    = string
  default = "20Gi"
}

variable "loki_storage_class_name" {
  description = "Optional storageClassName (e.g., local-path for k3s)"
  type        = string
  default     = ""
}

locals {
  loki_values_yaml = templatefile("${path.module}/templatefiles/loki_values.yaml.tpl", {
    retention_days      = var.loki_retention_days
    persistence_enabled = var.loki_persistence_enabled
    storage_size        = var.loki_storage_size
    storage_class_name  = var.loki_storage_class_name
  })

  promtail_values_yaml = templatefile("${path.module}/templatefiles/promtail_values.yaml.tpl", {})
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_chart_version

  values = [local.loki_values_yaml]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.kube_prometheus_stack
  ]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = var.promtail_chart_version

  values = [local.promtail_values_yaml]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.loki
  ]
}

# Grafana datasource picked by kube-prometheus-stack Grafana sidecar
resource "kubernetes_config_map" "grafana_loki_datasource" {
  metadata {
    name      = "grafana-datasource-loki"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "loki-datasource.yaml" = <<-YAML
      apiVersion: 1
      datasources:
        - name: Loki
          type: loki
          access: proxy
          url: http://loki-gateway.monitoring.svc.cluster.local
          isDefault: false
          editable: true
          jsonData:
            maxLines: 1000
    YAML
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
    helm_release.loki
  ]
}

# ServiceMonitor for Loki metrics (scraped by kube-prometheus-stack)
resource "kubernetes_manifest" "loki_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "loki"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "kube-prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "loki"
        }
      }
      namespaceSelector = {
        matchNames = [kubernetes_namespace.monitoring.metadata[0].name]
      }
      endpoints = [
        {
          port          = "http-metrics"  # Provided by the chart
          path          = "/metrics"
          interval      = "30s"
          scrapeTimeout = "10s"
        }
      ]
    }
  }

  depends_on = [
    helm_release.kube_prometheus_stack,
    helm_release.loki
  ]
}
