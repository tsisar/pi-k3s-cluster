# Create keycloak namespace
resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/instance" = var.namespace
    }
  }
}

# PostgreSQL PVC
resource "kubernetes_manifest" "postgres_pvc" {
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "postgres-data"
      namespace = var.namespace
      labels = {
        app = "postgres"
      }
    }
    spec = {
      accessModes = ["ReadWriteOnce"]
      resources = {
        requests = {
          storage = var.postgres_storage_size
        }
      }
    }
  }
  
  depends_on = [kubernetes_namespace.keycloak]
}

# PostgreSQL Deployment
resource "kubernetes_manifest" "postgres_deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "postgres"
      namespace = var.namespace
      labels = {
        app = "postgres"
      }
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "postgres"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "postgres"
          }
        }
        spec = {
          containers = [
            {
              name  = "postgres"
              image = var.postgres_image
              env = [
                {
                  name  = "POSTGRES_USER"
                  value = "keycloak"
                },
                {
                  name  = "POSTGRES_PASSWORD"
                  value = "keycloak"
                },
                {
                  name  = "POSTGRES_DB"
                  value = "keycloak"
                },
                {
                  name  = "POSTGRES_LOG_STATEMENT"
                  value = "all"
                }
              ]
              ports = [
                {
                  name          = "postgres"
                  containerPort = 5432
                }
              ]
              volumeMounts = [
                {
                  name      = "postgres-data"
                  mountPath = "/var/lib/postgresql"
                }
              ]
            }
          ]
          volumes = [
            {
              name = "postgres-data"
              persistentVolumeClaim = {
                claimName = "postgres-data"
              }
            }
          ]
        }
      }
    }
  }
  
  depends_on = [kubernetes_manifest.postgres_pvc]
}

# PostgreSQL Service
resource "kubernetes_manifest" "postgres_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "postgres"
      namespace = var.namespace
      labels = {
        app = "postgres"
      }
    }
    spec = {
      selector = {
        app = "postgres"
      }
      ports = [
        {
          protocol   = "TCP"
          port       = 5432
          targetPort = 5432
        }
      ]
      type = "ClusterIP"
    }
  }
  
  depends_on = [kubernetes_namespace.keycloak]
}

# Keycloak Discovery Service (Headless)
resource "kubernetes_manifest" "keycloak_discovery_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "keycloak-discovery"
      namespace = var.namespace
      labels = {
        app = "keycloak"
      }
    }
    spec = {
      selector = {
        app = "keycloak"
      }
      clusterIP = "None"
      type      = "ClusterIP"
    }
  }
  
  depends_on = [kubernetes_namespace.keycloak]
}

# Keycloak Service
resource "kubernetes_manifest" "keycloak_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "keycloak"
      namespace = var.namespace
      labels = {
        app = "keycloak"
      }
    }
    spec = {
      ports = [
        {
          protocol   = "TCP"
          port       = 8080
          targetPort = "http"
          name       = "http"
        }
      ]
      selector = {
        app = "keycloak"
      }
      type = "ClusterIP"
    }
  }
  
  depends_on = [kubernetes_namespace.keycloak]
}

# Keycloak StatefulSet
resource "kubernetes_manifest" "keycloak_statefulset" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "StatefulSet"
    metadata = {
      name      = "keycloak"
      namespace = var.namespace
      labels = {
        app = "keycloak"
      }
    }
    spec = {
      serviceName = "keycloak-discovery"
      replicas    = var.keycloak_replicas
      selector = {
        matchLabels = {
          app = "keycloak"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "keycloak"
          }
        }
        spec = {
          containers = [
            {
              name  = "keycloak"
              image = var.keycloak_image
              args  = ["start"]
              env = [
                {
                  name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
                  value = "admin"
                },
                {
                  name  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
                  value = "admin"
                },
                {
                  name  = "KC_PROXY_HEADERS"
                  value = "xforwarded"
                },
                {
                  name  = "KC_HTTP_ENABLED"
                  value = "true"
                },
                {
                  name  = "KC_HOSTNAME_STRICT"
                  value = "false"
                },
                {
                  name  = "KC_HEALTH_ENABLED"
                  value = "true"
                },
                {
                  name  = "KC_CACHE"
                  value = "ispn"
                },
                {
                  name = "POD_IP"
                  valueFrom = {
                    fieldRef = {
                      fieldPath = "status.podIP"
                    }
                  }
                },
                {
                  name  = "JAVA_OPTS_APPEND"
                  value = "-Djgroups.bind.address=$(POD_IP)"
                },
                {
                  name  = "KC_DB_URL_DATABASE"
                  value = "keycloak"
                },
                {
                  name  = "KC_DB_URL_HOST"
                  value = "postgres"
                },
                {
                  name  = "KC_DB"
                  value = "postgres"
                },
                {
                  name  = "KC_DB_PASSWORD"
                  value = "keycloak"
                },
                {
                  name  = "KC_DB_USERNAME"
                  value = "keycloak"
                }
              ]
              ports = [
                {
                  name          = "http"
                  containerPort = 8080
                }
              ]
              startupProbe = {
                httpGet = {
                  path = "/health/started"
                  port = 9000
                }
                periodSeconds    = 1
                failureThreshold = 600
              }
              readinessProbe = {
                httpGet = {
                  path = "/health/ready"
                  port = 9000
                }
                periodSeconds    = 10
                failureThreshold = 3
              }
              livenessProbe = {
                httpGet = {
                  path = "/health/live"
                  port = 9000
                }
                periodSeconds    = 10
                failureThreshold = 3
              }
              resources = {
                limits = {
                  cpu    = "2"
                  memory = "2000Mi"
                }
                requests = {
                  cpu    = "500m"
                  memory = "1700Mi"
                }
              }
            }
          ]
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_manifest.keycloak_discovery_service,
    kubernetes_manifest.postgres_service
  ]
}

# Keycloak Ingress
resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name      = "keycloak-ingress"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/instance" = var.namespace
    }
    annotations = {
      "kubernetes.io/ingress.class"                       = "nginx"
      "nginx.ingress.kubernetes.io/client-max-body-size"  = "100m"
      "nginx.ingress.kubernetes.io/proxy-body-size"       = "100m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "300"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"    = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.host
      http {
        path {
          backend {
            service {
              name = "keycloak"
              port {
                number = 8080
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.keycloak_service
  ]
}