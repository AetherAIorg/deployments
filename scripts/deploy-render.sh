#!/usr/bin/env bash
# Trigger Render deploy hooks for all backend services.
set -euo pipefail

trigger() {
  local name="$1"
  local var="$2"
  local url="${!var:-}"
  if [[ -z "$url" ]]; then
    echo "skip $name ($var not set)"
    return 0
  fi
  echo "deploy $name ..."
  curl -fsS -X POST "$url" -o /dev/null
  echo "ok $name"
}

trigger margin-api RENDER_DEPLOY_HOOK_API
trigger margin-worker RENDER_DEPLOY_HOOK_WORKER
trigger margin-hub RENDER_DEPLOY_HOOK_HUB
trigger margin-ingest RENDER_DEPLOY_HOOK_INGEST
trigger catalog-api RENDER_DEPLOY_HOOK_CATALOG

echo "Render deploy hooks triggered."
