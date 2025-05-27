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
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "pi-cluster"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "pi-cluster"
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
  address = try("http://${module.vault["enabled"].host_local}", var.vault_address)
  token   = try(module.vault["enabled"].root_token, var.vault_token)
}

