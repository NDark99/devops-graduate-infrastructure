variable "docker_host" {
  description = "Docker API endpoint. The default targets Docker inside Ubuntu."
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "application_image" {
  description = "Container image published by the application pipeline."
  type        = string
  default     = "devops-graduate-app:test"
}

variable "application_version" {
  description = "Version displayed by the application."
  type        = string
  default     = "local"
}

variable "image_digest" {
  description = "Immutable commit SHA used to trigger pulling a newer moving tag."
  type        = string
  default     = "local"
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

variable "discord_webhook_url" {
  description = "Optional Discord webhook used by Alertmanager."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition = (
      var.discord_webhook_url == "" ||
      can(regex("^https://(discord.com|discordapp.com)/api/webhooks/", var.discord_webhook_url))
    )
    error_message = "Use an empty value or a valid Discord webhook URL."
  }
}

variable "vm_ip" {
  description = "Static private IP configured in the Vagrantfile."
  type        = string
  default     = "192.168.56.10"
}
