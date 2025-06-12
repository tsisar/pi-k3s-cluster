variable "name" {
  description = "The name of the demo application"
  type        = string
  default     = "demo"
}

variable "namespace" {
  description = "Namespace for the demo application"
  type        = string
  default     = "demo"
}

variable "repository" {
  description = "GitHub repository URL"
  type        = string
}

variable "host" {
  description = "Host for the demo application"
  type        = string
}