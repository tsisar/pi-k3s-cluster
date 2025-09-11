terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
    }
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.86.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = ">= 7.8.2"
    }
  }
}
