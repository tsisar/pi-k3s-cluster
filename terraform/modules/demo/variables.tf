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

variable "repo_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "target_revision" {
  description = "GitHub target revision (branch)"
  type        = string
}

variable "host" {
  description = "Host for the demo application"
  type        = string
}