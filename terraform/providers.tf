terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    mikrotik = {
      source  = "ddelnano/mikrotik"
      version = "0.16.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.8.2"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "pi-k3s-cluster"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "pi-k3s-cluster"
  }
}

provider "mikrotik" {
  host     = "192.168.88.1:8728"
  username = var.mikrotik_username
  password = var.mikrotik_password
  insecure = true
}

provider "tls" {}

provider "vault" {
  address = try("https://${module.vault["enabled"].host_external}", var.vault_address)
  token   = try(module.vault["enabled"].root_token, var.vault_token)
}

provider "argocd" {
  server_addr = try(module.argo_cd["enabled"].host, "https://argo.tsisar.com.ua")
  username    = try(module.argo_cd["enabled"].username, "admin")
  password    = try(module.argo_cd["enabled"].password, "")
}
