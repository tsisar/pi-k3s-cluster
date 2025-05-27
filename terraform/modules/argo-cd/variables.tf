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

variable "dex_git_hub_client_id" {
  description = "Dex GitHub client ID"
  type        = string
}

variable "dex_git_hub_client_secret" {
  description = "Dex GitHub client secret"
  type        = string
}