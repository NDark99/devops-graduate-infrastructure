output "application_url" {
  value = "http://${var.vm_ip}:8080"
}

output "grafana_url" {
  value = "http://${var.vm_ip}:3000"
}

output "prometheus_url" {
  value = "http://${var.vm_ip}:9090"
}

output "health_url" {
  value = "http://${var.vm_ip}:8080/health"
}
