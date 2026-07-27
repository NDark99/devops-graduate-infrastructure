variable "aws_region" {
  description = "AWS region used for all resources."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "devops-graduate"
}

variable "instance_type" {
  description = "EC2 instance type. t3.small is suitable for the monitoring stack."
  type        = string
  default     = "t3.small"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR notation, for example 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid IPv4 CIDR."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key used to access the Ubuntu instance."
  type        = string
  sensitive   = true
}

variable "application_image" {
  description = "Initial container image. CI/CD replaces it with the latest main image."
  type        = string
  default     = "nginx:alpine"
}

variable "grafana_admin_password" {
  description = "Initial Grafana administrator password."
  type        = string
  sensitive   = true

  validation {
    condition = (
      length(var.grafana_admin_password) >= 12 &&
      can(regex("^[A-Za-z0-9!@%_+=.-]+$", var.grafana_admin_password))
    )
    error_message = "Use at least 12 characters from: letters, digits, ! @ % _ + = . -"
  }
}
