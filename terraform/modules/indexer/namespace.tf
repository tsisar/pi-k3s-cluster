# Create namespace
resource "kubernetes_namespace" "indexer" {
  metadata {
    name = var.namespace
  }
}