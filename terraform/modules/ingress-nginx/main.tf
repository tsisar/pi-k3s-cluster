resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]
}

# Create cluster-wide Gateway for Gateway API
resource "kubernetes_manifest" "cluster_gateway" {
  manifest = yamldecode(file("${path.module}/gateway.yaml"))
  
  depends_on = [helm_release.ingress_nginx]
}