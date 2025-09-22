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

variable "enabled_modules" {
  type    = map(bool)
  default = {}
}

variable "hosts" {
  type    = map(string)
  default = {}
}

variable "influxdb_token" {
  description = "InfluxDB token"
  type        = string
  sensitive   = true
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
