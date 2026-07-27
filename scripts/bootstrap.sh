#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  docker.io \
  docker-compose-v2 \
  gnupg \
  jq \
  lsb-release \
  unzip \
  ufw

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y terraform

systemctl enable --now docker
usermod -aG docker vagrant
install -d -o vagrant -g vagrant /opt/devops-terraform

ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.56.0/24 to any port 22 proto tcp
ufw allow from 192.168.56.0/24 to any port 8080 proto tcp
ufw allow from 192.168.56.0/24 to any port 3000 proto tcp
ufw allow from 192.168.56.0/24 to any port 9090 proto tcp
ufw --force enable

echo "Bootstrap completed. Reconnect with 'vagrant ssh' to refresh Docker group membership."
