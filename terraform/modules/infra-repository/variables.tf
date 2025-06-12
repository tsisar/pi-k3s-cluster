variable "environment" {
  description = "environment"
  type        = string
  default     = "production"
}

variable "repository_name" {
  description = "GitHub repository URL"
  type        = string
  default     = "pi-k3s-cluster"
}