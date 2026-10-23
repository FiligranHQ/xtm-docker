#!/usr/bin/env bash
# Host preparation for running the XTM stack on rootless Podman (RHEL / Rocky 9).
# Run once as the user that will own the containers (needs sudo for the host-level steps).
# Validated on Rocky Linux 9.8 with Podman 5.8.2 and SELinux enforcing.
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this script as the rootless user that will run the stack, not as root." >&2
  exit 1
fi

TARGET_USER="$(id -un)"

echo "==> Elasticsearch: vm.max_map_count=1048575 (persistent)"
echo 'vm.max_map_count = 1048575' | sudo tee /etc/sysctl.d/90-xtm-elasticsearch.conf >/dev/null
sudo sysctl -q -p /etc/sysctl.d/90-xtm-elasticsearch.conf

echo "==> OpenSandbox egress: preload netfilter modules (rootless netns cannot autoload them)"
sudo tee /etc/modules-load.d/90-xtm-opensandbox.conf >/dev/null <<'MODS'
# OpenSandbox egress sidecar: rootless Podman cannot autoload netfilter modules
xt_REDIRECT
nft_redir
xt_owner
iptable_nat
nft_ct
nft_reject
nft_reject_inet
nft_limit
nft_fib_inet
nft_log
MODS
sudo systemctl restart systemd-modules-load.service

echo "==> Keep the user's services running without an open session (linger)"
sudo loginctl enable-linger "${TARGET_USER}"

echo "==> Podman API socket (used by xtm-composer and opensandbox)"
systemctl --user enable --now podman.socket

echo "==> Restart 'restart: always' containers at boot"
# Rootless Podman does NOT restart containers after a reboot unless this unit is enabled.
systemctl --user enable podman-restart.service

echo
echo "Done. Set this in .env:"
echo "  CONTAINER_ENGINE_SOCKET=/run/user/$(id -u)/podman/podman.sock"
echo "Then start the stack with:"
echo "  docker compose -f docker-compose.yml -f docker-compose.podman.yml up -d"
