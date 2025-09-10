# Smartctl Exporter DaemonSet
resource "kubernetes_daemon_set_v1" "smartctl_exporter" {
  count = var.smartctl_exporter_enabled ? 1 : 0
  metadata {
    name      = "smartctl-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "smartctl-exporter"
      "app.kubernetes.io/part-of" = "node-metrics"
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "smartctl-exporter"
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "smartctl-exporter"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9633"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        toleration {
          key    = "node-role.kubernetes.io/control-plane"
          effect = "NoSchedule"
        }

        toleration {
          key      = "node.kubernetes.io/not-ready"
          operator = "Exists"
          effect   = "NoExecute"
        }

        host_pid = false
        host_ipc = false
        host_network = false

        container {
          name  = "smartctl-exporter"
          image = var.smartctl_exporter_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 9633
          }

          security_context {
            privileged                 = true
            run_as_user               = 0
            allow_privilege_escalation = true
          }

          volume_mount {
            name       = "dev"
            mount_path = "/dev"
          }

          volume_mount {
            name       = "run-udev"
            mount_path = "/run/udev"
            read_only  = true
          }

          volume_mount {
            name       = "sys-block"
            mount_path = "/sys/block"
            read_only  = true
          }

          args = [
            "--smartctl.interval=${var.smartctl_exporter_interval}",
            "--smartctl.device-include=^(nvme|sd)",
            "--smartctl.rescan=${var.smartctl_exporter_rescan}"
          ]

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/metrics"
              port = 9633
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 2
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/metrics"
              port = 9633
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        termination_grace_period_seconds = 10

        volume {
          name = "dev"
          host_path {
            path = "/dev"
            type = "Directory"
          }
        }

        volume {
          name = "run-udev"
          host_path {
            path = "/run/udev"
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "sys-block"
          host_path {
            path = "/sys/block"
            type = "Directory"
          }
        }
      }
    }
  }
}

# Smartctl Exporter Service
resource "kubernetes_service_v1" "smartctl_exporter" {
  count = var.smartctl_exporter_enabled ? 1 : 0
  metadata {
    name      = "smartctl-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "smartctl-exporter"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name" = "smartctl-exporter"
    }

    port {
      name        = "http"
      port        = 9633
      target_port = 9633
    }
  }
}

# Smartctl Exporter ServiceMonitor
resource "kubernetes_manifest" "smartctl_exporter_servicemonitor" {
  count = var.smartctl_exporter_enabled ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "smartctl-exporter"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      jobLabel = "app_kubernetes_io_name"
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "smartctl-exporter"
        }
      }
      namespaceSelector = {
        matchNames = ["monitoring"]
      }
      endpoints = [
        {
          port          = "http"
          path          = "/metrics"
          interval      = "60s"
          scrapeTimeout = "10s"
        }
      ]
    }
  }
}
