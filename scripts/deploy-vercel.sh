#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${VERCEL_TOKEN:-}" ]]; then
  echo "error: VERCEL_TOKEN required" >&2
  exit 1
fi

deploy_project() {
  local dir="$1"
  local project_id_var="$2"
  local project_id="${!project_id_var:-}"

  if [[ ! -d "$dir" ]]; then
    echo "skip $dir (missing — init submodule first)" >&2
    return 0
  fi

  echo "deploying $dir ..."
  local args=(deploy "$dir" --prod --token "$VERCEL_TOKEN" --yes)
  if [[ -n "$project_id" ]]; then
    args+=(--project "$project_id")
  fi
  if [[ -n "${VERCEL_ORG_ID:-}" ]]; then
    args+=(--scope "$VERCEL_ORG_ID")
  fi
  vercel "${args[@]}"
}

if ! command -v vercel >/dev/null 2>&1; then
  npm install -g vercel@latest
fi

deploy_project app/metricgraph/frontend VERCEL_PROJECT_ID_APP
deploy_project app/registry_governance/frontend VERCEL_PROJECT_ID_CATALOG

echo "Vercel deploys complete."
