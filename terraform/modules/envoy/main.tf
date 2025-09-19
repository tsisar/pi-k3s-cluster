variable "gateway_class_name" {
  description = "Name of the GatewayClass"
  type        = string
  default     = "eg"
}

variable "gateway_namespace" {
  description = "Namespace for the demo application"
  type        = string
  default     = "envoy-gateway-system"
}

variable "gateway_name" {
  description = "Name of the Gateway"
  type        = string
  default     = "eg"
}

variable "helm_version" {
  type    = string
  default = "v1.5.1"
}

resource "kubernetes_namespace" "eg" {
  metadata { name = var.gateway_namespace }
}

resource "helm_release" "eg" {
  name      = "envoy-gateway"
  namespace = kubernetes_namespace.eg.metadata[0].name

  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-helm"
  version    = var.helm_version

  values    = [file("${path.module}/values.yaml")]
  skip_crds = true

  create_namespace = true
  atomic           = true
  wait             = true
  timeout          = 600
}

resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata   = { name = var.gateway_class_name }
    spec       = { controllerName = "gateway.envoyproxy.io/gatewayclass-controller" }
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = var.gateway_name
      namespace = var.gateway_namespace
    }
    spec = {
      gatewayClassName = var.gateway_class_name
      listeners = [
        {
          name          = "http", protocol = "HTTP", port = 8080
          allowedRoutes = { kinds = [{ kind = "HTTPRoute" }], namespaces = { from = "All" } }
        },
        # {
        #   name = "https", protocol = "HTTPS", port = 443
        #   tls = { mode = "Terminate", certificateRefs = [{ kind = "Secret", name = "eg-tls" }] }
        #   allowedRoutes = { kinds = [{ kind = "HTTPRoute" }], namespaces = { from = "All" } }
        # }
      ]
    }
  }
  depends_on = [
    kubernetes_manifest.gateway_class,
  ]
}
