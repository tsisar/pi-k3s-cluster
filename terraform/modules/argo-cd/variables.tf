variable "email" {
  description = "email"
  type        = string
}

variable "server_insecure" {
  description = "local deploy"
  type        = bool
  default     = false
}

variable "letsencrypt_server" {
    description = "letsencrypt server (staging or production, default is production)"
    type        = string
    default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "host" {
    description = "host"
    type        = string
}

variable "nexus_api_url" {
  type = string
}

variable "nexus_prefix" {
  type = string
}

variable "nexus_username" {
  type = string
}

variable "nexus_password" {
  type      = string
  sensitive = true
}