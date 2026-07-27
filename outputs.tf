output "server_ip" {
  description = "Elastic public IP used by the application and CI/CD."
  value       = aws_eip.server.public_ip
}

output "application_url" {
  value = "http://${aws_eip.server.public_ip}"
}

output "grafana_url" {
  value = "http://${aws_eip.server.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_eip.server.public_ip}:9090"
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_eip.server.public_ip}"
}
