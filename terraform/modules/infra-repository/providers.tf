terraform {
  required_providers {
    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.8.2"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.3.0"
    }
  }
}
