resource "kubernetes_namespace" "db" {
  metadata {
    name = var.namespace
  }
}
