#!/usr/bin/env bash
# Bootstrap a DigitalOcean Droplet for the Margin MVP backend.
# Run as root on a fresh Ubuntu 24.04 droplet:
#   curl -fsSL https://raw.githubusercontent.com/AetherAIorg/deployments/main/scripts/setup-droplet.sh | bash
set -euo pipefail

DEPLOYMENTS_REPO="${DEPLOYMENTS_REPO:-https://github.com/AetherAIorg/deployments.git}"
INSTALL_DIR="${INSTALL_DIR:-/root/deployments}"
COMPOSE_FILE="do/docker-compose.prod.yml"
ENV_FILE="do/.env"

echo "==> Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl git
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

echo "==> Cloning deployments repo..."
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" pull origin main
else
  git clone "$DEPLOYMENTS_REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
git submodule update --init --recursive

echo "==> Configuring environment..."
if [[ ! -f "$ENV_FILE" ]]; then
  cp do/.env.production.example "$ENV_FILE"
  POSTGRES_PASSWORD="$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)"
  sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" "$ENV_FILE"
  echo "Created $ENV_FILE with a random POSTGRES_PASSWORD."
  echo "Edit $ENV_FILE to set API_DOMAIN, AUTH_SECRET, CORS_ORIGINS, Neo4j, and S3 before going live."
else
  echo "Using existing $ENV_FILE"
fi

echo "==> Starting stack..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build

API_DOMAIN="$(grep '^API_DOMAIN=' "$ENV_FILE" | cut -d= -f2- || true)"
echo ""
echo "Done. Stack is running in $INSTALL_DIR"
echo "Health check (after DNS + TLS propagate):"
if [[ -n "$API_DOMAIN" && "$API_DOMAIN" != "localhost" && "$API_DOMAIN" != "api.yourdomain.com" ]]; then
  echo "  curl -fsS https://${API_DOMAIN}/api/health"
else
  echo "  curl -fsS http://$(curl -fsS ifconfig.me 2>/dev/null || echo '<droplet-ip>')/api/health"
  echo "Set API_DOMAIN in $ENV_FILE and redeploy for HTTPS."
fi
