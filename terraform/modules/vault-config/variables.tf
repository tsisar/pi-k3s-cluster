variable "namespace" {
  description = "Namespace for Vault"
  type        = string
  default     = "vault"
}

variable "host_local" {
  description = "Host for local environment"
  type        = string
}

variable "host_external" {
  description = "Host for external environment"
  type        = string
}