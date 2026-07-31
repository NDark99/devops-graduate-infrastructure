locals {
  monitoring_dir = abspath("${path.module}/monitoring")
}

resource "docker_network" "monitoring" {
  name = "devops-monitoring"
}

resource "docker_volume" "prometheus" {
  name = "devops-prometheus-data"
}

resource "docker_volume" "grafana" {
  name = "devops-grafana-data"
}

resource "docker_volume" "loki" {
  name = "devops-loki-data"
}

resource "docker_volume" "promtail" {
  name = "devops-promtail-data"
}

resource "docker_volume" "alertmanager" {
  name = "devops-alertmanager-data"
}

resource "docker_image" "application" {
  name         = var.application_image
  keep_locally = true
  pull_triggers = [
    var.image_digest
  ]
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v3.5.0"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:12.1.0"
  keep_locally = true
}

resource "docker_image" "loki" {
  name         = "grafana/loki:3.5.3"
  keep_locally = true
}

resource "docker_image" "promtail" {
  name         = "grafana/promtail:3.5.3"
  keep_locally = true
}

resource "docker_image" "node_exporter" {
  name         = "prom/node-exporter:v1.9.1"
  keep_locally = true
}

resource "docker_image" "cadvisor" {
  name         = "gcr.io/cadvisor/cadvisor:v0.52.1"
  keep_locally = true
}

resource "docker_image" "alertmanager" {
  name         = "prom/alertmanager:v0.32.1"
  keep_locally = true
}

resource "docker_container" "application" {
  name    = "devops-app"
  image   = docker_image.application.image_id
  restart = "unless-stopped"

  env = [
    "APP_VERSION=${var.application_version}"
  ]

  ports {
    internal = 8080
    external = 8080
    ip       = "0.0.0.0"
  }

  networks_advanced {
    name    = docker_network.monitoring.name
    aliases = ["app"]
  }

  healthcheck {
    test         = ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
    interval     = "15s"
    timeout      = "3s"
    retries      = 5
    start_period = "10s"
  }
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--storage.tsdb.retention.time=15d"
  ]

  ports {
    internal = 9090
    external = 9090
    ip       = "0.0.0.0"
  }

  mounts {
    target    = "/etc/prometheus/prometheus.yml"
    source    = "${local.monitoring_dir}/prometheus/prometheus.yml"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/etc/prometheus/alerts.yml"
    source    = "${local.monitoring_dir}/prometheus/alerts.yml"
    type      = "bind"
    read_only = true
  }

  mounts {
    target = "/prometheus"
    source = docker_volume.prometheus.name
    type   = "volume"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  depends_on = [docker_container.alertmanager]
}

resource "docker_container" "alertmanager" {
  name    = "alertmanager"
  image   = docker_image.alertmanager.image_id
  restart = "unless-stopped"

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml",
    "--storage.path=/alertmanager",
    "--enable-feature=utf8-strict-mode"
  ]

  upload {
    file        = "/etc/alertmanager/alertmanager.yml"
    content     = file("${local.monitoring_dir}/alertmanager/alertmanager.local.yml")
    permissions = "0644"
  }

  mounts {
    target = "/alertmanager"
    source = docker_volume.alertmanager.name
    type   = "volume"
  }

  ports {
    internal = 9093
    external = 9093
    ip       = "0.0.0.0"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "loki" {
  name    = "loki"
  image   = docker_image.loki.image_id
  restart = "unless-stopped"
  command = ["-config.file=/etc/loki/local-config.yaml"]

  mounts {
    target    = "/etc/loki/local-config.yaml"
    source    = "${local.monitoring_dir}/loki/loki.yml"
    type      = "bind"
    read_only = true
  }

  mounts {
    target = "/loki"
    source = docker_volume.loki.name
    type   = "volume"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_AUTH_ANONYMOUS_ENABLED=true",
    "GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer",
    "GF_AUTH_ANONYMOUS_HIDE_VERSION=true",
    "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/devops-overview.json"
  ]

  ports {
    internal = 3000
    external = 3000
    ip       = "0.0.0.0"
  }

  mounts {
    target = "/var/lib/grafana"
    source = docker_volume.grafana.name
    type   = "volume"
  }

  mounts {
    target    = "/etc/grafana/provisioning"
    source    = "${local.monitoring_dir}/grafana/provisioning"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/var/lib/grafana/dashboards"
    source    = "${local.monitoring_dir}/grafana/dashboards"
    type      = "bind"
    read_only = true
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  depends_on = [
    docker_container.prometheus,
    docker_container.loki
  ]
}

resource "docker_container" "node_exporter" {
  name       = "node-exporter"
  image      = docker_image.node_exporter.image_id
  restart    = "unless-stopped"
  command    = ["--path.rootfs=/host"]
  privileged = true

  mounts {
    target    = "/host"
    source    = "/"
    type      = "bind"
    read_only = true
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "cadvisor" {
  name       = "cadvisor"
  image      = docker_image.cadvisor.image_id
  restart    = "unless-stopped"
  privileged = true

  mounts {
    target    = "/rootfs"
    source    = "/"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/var/run"
    source    = "/var/run"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/sys"
    source    = "/sys"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/var/lib/docker"
    source    = "/var/lib/docker"
    type      = "bind"
    read_only = true
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "promtail" {
  name    = "promtail"
  image   = docker_image.promtail.image_id
  restart = "unless-stopped"
  command = ["-config.file=/etc/promtail/config.yml"]

  mounts {
    target    = "/etc/promtail/config.yml"
    source    = "${local.monitoring_dir}/promtail/promtail.yml"
    type      = "bind"
    read_only = true
  }

  mounts {
    target    = "/var/run/docker.sock"
    source    = "/var/run/docker.sock"
    type      = "bind"
    read_only = true
  }

  mounts {
    target = "/var/lib/promtail"
    source = docker_volume.promtail.name
    type   = "volume"
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  depends_on = [docker_container.loki]
}
