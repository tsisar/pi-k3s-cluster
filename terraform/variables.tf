variable "domain" {
  description = "Domain"
  type        = string
  default     = "local"
}

variable "email" {
  description = "Email"
  type        = string
  default     = "admin@example.com"
}

variable "mikrotik_username" {
  description = "Mikrotik username"
  type        = string
}

variable "mikrotik_password" {
  description = "Mikrotik password"
  type        = string
}

variable "dex_git_hub_client_id" {
  description = "Dex GitHub client ID"
  type        = string
  default = ""
}

variable "dex_git_hub_client_secret" {
  description = "Dex GitHub client secret"
  type        = string
  sensitive   = true
  default = ""
}

variable "enabled_modules" {
  type = map(bool)
  default = {}
}

variable "hosts" {
  type = map(string)
  default = {}
}

variable "influxdb_token" {
  description = "InfluxDB token"
  type        = string
  sensitive   = true
}
