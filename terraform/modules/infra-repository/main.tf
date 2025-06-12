locals {
  repository = "git@github.com:Tsisar/${var.repository_name}"
}
# Generate an ssh key using provider "hashicorp/tls"
resource "tls_private_key" "repository_deploy_key" {
  algorithm = "ED25519"
}

# Add the ssh key as a deploy key
resource "github_repository_deploy_key" "deploy_key" {
  title      = "ArgoCD Deploy Key (${var.environment})"
  repository = var.repository_name
  key        = tls_private_key.repository_deploy_key.public_key_openssh
  read_only  = true
}

# Connect repository to Argo CD
resource "argocd_repository" "private" {
  repo            = local.repository
  name            = var.repository_name
  project         = "default"
  username        = "git"
  ssh_private_key = tls_private_key.repository_deploy_key.private_key_openssh
  insecure        = false
}

output "repository" {
  value = local.repository
}