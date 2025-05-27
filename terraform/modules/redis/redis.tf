resource "kubernetes_stateful_set" "redis" {
  metadata {
    name      = var.redis_name
    namespace = kubernetes_namespace.db.metadata[0].name
  }

  spec {
    service_name = kubernetes_service.redis.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = var.redis_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.redis_name
        }
      }

      spec {
        container {
          name  = var.redis_name
          image = var.redis_image

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-storage"
            mount_path = "/data"
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "redis-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = var.redis_name
    namespace = kubernetes_namespace.db.metadata[0].name
  }

  spec {
    cluster_ip = "None"

    selector = {
      app = var.redis_name
    }

    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_service" "redis_nodeport" {
  metadata {
    name      = "redis-nodeport"
    namespace = kubernetes_namespace.db.metadata[0].name
  }

  spec {
    selector = {
      app = var.redis_name
    }

    type = "NodePort"

    port {
      port        = 6379
      target_port = 6379
      node_port   = var.redis_nodeport
      protocol    = "TCP"
    }
  }
}

