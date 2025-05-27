resource "kubernetes_deployment" "redis_commander" {
  metadata {
    name      = var.commander_name
    namespace = kubernetes_namespace.db.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.commander_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.commander_name
        }
      }

      spec {
        container {
          name  = var.commander_name
          image = "ghcr.io/joeferner/redis-commander:latest"

          port {
            container_port = kubernetes_service.redis_commander.spec[0].port[0].target_port
          }

          env {
            name  = "REDIS_HOSTS"
            value = kubernetes_service.redis.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis_commander" {
  metadata {
    name      = var.commander_name
    namespace = kubernetes_namespace.db.metadata[0].name
  }

  spec {
    selector = {
      app = var.commander_name
    }

    port {
      protocol    = "TCP"
      port        = 8081
      target_port = 8081
    }
  }
}

resource "kubernetes_ingress_v1" "redis_commander" {
  metadata {
    name      = "redis-commander-ingress"
    namespace = kubernetes_namespace.db.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.commander_host
      http {
        path {
          backend {
            service {
              name = kubernetes_service.redis_commander.metadata[0].name
              port {
                number = kubernetes_service.redis_commander.spec[0].port[0].port
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

