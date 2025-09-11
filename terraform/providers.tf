provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "local-k3s"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "local-k3s"
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
