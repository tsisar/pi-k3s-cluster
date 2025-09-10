terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
      version = ">= 3.0.2"
    }
    routeros = {
      source = "terraform-routeros/routeros"
      version = "1.86.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = ">= 7.8.2"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k3s-cluster"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "k3s-cluster"
  }
}

provider "routeros" {
  hosturl        = "http://192.168.88.1"
  username       = var.mikrotik_username
  password       = var.mikrotik_password
  insecure       = true
}

provider "tls" {}

provider "argocd" {
  server_addr = try(module.argo_cd["enabled"].host, "https://argo.example.com")
  username    = try(module.argo_cd["enabled"].username, "admin")
  password    = try(module.argo_cd["enabled"].password, "")
}
