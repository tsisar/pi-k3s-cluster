variable "prometheus_host" {
  description = "Prometheus host"
  type        = string
}

variable "grafana_host" {
  description = "Grafana host"
  type        = string
}

variable "influxdb_host" {
  description = "InfluxDB host"
  type        = string
  default     = "192.168.88.30"
}

variable "influxdb_port" {
  description = "InfluxDB port"
  type        = number
  default     = 8086
}

variable "influxdb_org" {
  description = "InfluxDB organization"
  type        = string
  default     = "k3s-cluster"
}

variable "influxdb_bucket" {
  description = "InfluxDB bucket"
  type        = string
  default     = "telegraf"
}

variable "influxdb_token" {
  description = "InfluxDB token"
  type        = string
  sensitive   = true
}

variable "smartctl_exporter_enabled" {
  description = "Enable smartctl-exporter for S.M.A.R.T monitoring"
  type        = bool
  default     = true
}

variable "smartctl_exporter_image" {
  description = "Smartctl exporter image"
  type        = string
  default     = "prometheuscommunity/smartctl-exporter:latest"
}

variable "smartctl_exporter_interval" {
  description = "Smartctl check interval"
  type        = string
  default     = "60s"
}

variable "smartctl_exporter_rescan" {
  description = "Smartctl rescan interval"
  type        = string
  default     = "10m"
}
