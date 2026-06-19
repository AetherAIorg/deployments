#!/usr/bin/env bash
# Run alembic migrations on Render via one-off jobs (requires RENDER_API_KEY).
set -euo pipefail

if [[ -z "${RENDER_API_KEY:-}" ]]; then
  echo "RENDER_API_KEY not set — migrations should run via preDeployCommand on deploy."
  echo "To run manually: Render Dashboard → margin-api shell → alembic upgrade head"
  exit 0
fi

run_migration() {
  local service_id="$1"
  local label="$2"
  if [[ -z "$service_id" ]]; then
    echo "skip $label (service id not set)"
    return 0
  fi
  echo "starting one-off migration job for $label ..."
  curl -fsS -X POST "https://api.render.com/v1/services/${service_id}/jobs" \
    -H "Authorization: Bearer ${RENDER_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"startCommand":"alembic upgrade head"}' | head -c 200
  echo ""
}

run_migration "${RENDER_SERVICE_ID_API:-}" "margin-api"
run_migration "${RENDER_SERVICE_ID_CATALOG:-}" "catalog-api"
