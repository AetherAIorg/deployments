#!/usr/bin/env bash
# Redeploy MVP backend on the DigitalOcean droplet (run locally via SSH or in CI).
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/root/deployments}"
COMPOSE_FILE="do/docker-compose.prod.yml"
ENV_FILE="do/.env"

cd "$INSTALL_DIR"
git pull origin main
git submodule update --init --recursive
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build

echo "DigitalOcean deploy complete."
