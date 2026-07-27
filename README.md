# DevOps Graduate Project — infrastruktura

Drugie repozytorium projektu zawierające kompletną infrastrukturę jako kod.
Terraform tworzy od zera sieć AWS, firewall, klucz, serwer Ubuntu oraz Elastic
IP. Cloud-init instaluje Dockera, konfiguruje UFW i uruchamia monitoring.

## Tworzone zasoby

- VPC `10.42.0.0/16`,
- publiczna podsieć i routing przez Internet Gateway,
- Security Group,
- EC2 z Ubuntu 24.04 LTS,
- szyfrowany wolumen GP3,
- Elastic IP,
- klucz SSH,
- Docker Compose z Prometheus, Grafana, Loki, Promtail, node-exporter i cAdvisor.

## Wymagania

- konto AWS z uprawnieniami do EC2/VPC,
- AWS CLI z ustawionymi danymi dostępowymi lub zmienne `AWS_*`,
- Terraform co najmniej 1.7,
- para kluczy SSH.

Uwaga: zasoby AWS mogą generować opłaty. Po ćwiczeniach użyj
`terraform destroy`.

## Wdrożenie od zera

1. Utwórz klucz, jeśli jeszcze go nie masz:

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/devops-graduate
   ```

2. Skopiuj plik konfiguracyjny:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. W `terraform.tfvars` ustaw:

   - własny publiczny adres IP jako `admin_cidr`,
   - zawartość pliku `.pub` jako `ssh_public_key`,
   - login GitHub w `application_image`,
   - silne hasło Grafany.

4. Utwórz infrastrukturę:

   ```bash
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   ```

5. Poczekaj kilka minut na zakończenie cloud-init:

   ```bash
   ssh -i ~/.ssh/devops-graduate ubuntu@$(terraform output -raw server_ip)
   cloud-init status --wait
   sudo docker compose -f /opt/devops/compose.yaml ps
   ```

Polecenia są idempotentne: ponowne `terraform apply` doprowadza zasoby do stanu
opisanego w kodzie, zamiast tworzyć ich duplikaty.

## Dostęp

```bash
terraform output application_url
terraform output grafana_url
terraform output prometheus_url
```

Domyślne konto Grafany to `admin`; hasło pochodzi z
`grafana_admin_password`. Dashboard `DevOps Project Overview` jest
provisionowany automatycznie.

## Reguły firewalla

| Port | Usługa | Źródło |
|---:|---|---|
| 22 | SSH | tylko `admin_cidr` |
| 80 | aplikacja | Internet |
| 3000 | Grafana | tylko `admin_cidr` |
| 9090 | Prometheus | tylko `admin_cidr` |

Te same ograniczenia dla portów administracyjnych są ustawione w AWS Security
Group i lokalnym firewallu UFW.

## Usunięcie infrastruktury

```bash
terraform plan -destroy
terraform destroy
```

Po usunięciu sprawdź w konsoli AWS, czy nie pozostały płatne zasoby.

## Stan Terraform

W wersji zaliczeniowej stan jest lokalny i ignorowany przez Git. W pracy
zespołowej należałoby dodać backend S3 z blokadą stanu. Plik
`.terraform.lock.hcl` jest wersjonowany, aby każdy używał tej samej wersji
providera AWS.
