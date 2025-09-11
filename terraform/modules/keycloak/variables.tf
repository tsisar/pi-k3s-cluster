variable "host" {
  description = "Keycloak hostname"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "keycloak"
}

variable "keycloak_image" {
  description = "Keycloak container image"
  type        = string
  default     = "quay.io/keycloak/keycloak:26.3.3"
}

variable "postgres_image" {
  description = "PostgreSQL container image"
  type        = string
  default     = "mirror.gcr.io/postgres:17"
}

variable "keycloak_replicas" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 1
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "10Gi"
}