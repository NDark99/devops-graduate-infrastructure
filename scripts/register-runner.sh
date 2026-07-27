#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <repository-url> <one-hour-registration-token>" >&2
  exit 1
fi

repository_url="$1"
registration_token="$2"
runner_dir="/home/vagrant/actions-runner"

if [[ -f "${runner_dir}/.runner" ]]; then
  echo "Runner is already registered."
  exit 0
fi

release_json="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest)"
runner_version="$(jq -r '.tag_name | ltrimstr("v")' <<<"${release_json}")"
asset_name="actions-runner-linux-x64-${runner_version}.tar.gz"
download_url="$(jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .browser_download_url' <<<"${release_json}")"
expected_digest="$(jq -r --arg name "${asset_name}" '.assets[] | select(.name == $name) | .digest // empty' <<<"${release_json}")"

if [[ -z "${download_url}" || "${download_url}" == "null" ]]; then
  echo "Could not find ${asset_name} in the latest GitHub Actions Runner release." >&2
  exit 1
fi

mkdir -p "${runner_dir}"
curl -fL "${download_url}" -o "${runner_dir}/${asset_name}"

if [[ "${expected_digest}" == sha256:* ]]; then
  echo "${expected_digest#sha256:}  ${runner_dir}/${asset_name}" | sha256sum --check -
fi

tar -xzf "${runner_dir}/${asset_name}" -C "${runner_dir}"
rm "${runner_dir}/${asset_name}"

cd "${runner_dir}"
./config.sh \
  --unattended \
  --url "${repository_url}" \
  --token "${registration_token}" \
  --name "devops-local-vm" \
  --labels "devops-local" \
  --work "_work"

sudo ./svc.sh install vagrant
sudo ./svc.sh start

echo "GitHub Actions Runner registered and started as a systemd service."
