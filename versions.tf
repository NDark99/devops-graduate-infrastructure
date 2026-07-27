terraform {
  required_version = ">= 1.7.0"

  backend "local" {}

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

provider "docker" {
  host = var.docker_host
}
