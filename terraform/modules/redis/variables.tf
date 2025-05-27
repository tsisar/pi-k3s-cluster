variable "namespace" {
  description = "Namespace for Redis"
  type        = string
  default     = "core"
}

variable "redis_image" {
  description = "Redis image"
  type        = string
  default     = "redis:6.2.5-alpine"
}

variable "redis_name" {
  description = "Redis name"
  type        = string
  default     = "redis"
}

variable "redis_nodeport" {
  description = "Redis NodePort"
  type        = number
  default     = 30079
}

variable "commander_name" {
  description = "Redis Commander name"
  type        = string
  default     = "redis-commander"
}

variable "redis_host" {
  description = "Redis host"
  type        = string
}

variable "commander_host" {
  description = "Redis Commander host"
  type        = string
}