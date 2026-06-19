#!/usr/bin/env bash
set -euo pipefail

check() {
  local label="$1"
  local url="$2"
  if [[ -z "$url" ]]; then
    echo "skip $label (URL not set)"
    return 0
  fi
  echo -n "$label ($url) ... "
  if curl -fsS --max-time 30 "$url" >/dev/null; then
    echo "ok"
  else
    echo "FAIL"
    return 1
  fi
}

failed=0
check "MetricGraph API" "${API_URL:-}/api/health" || failed=1
check "Integration Hub" "${HUB_URL:-}/health" || failed=1
check "Catalog API" "${CATALOG_API_URL:-}/api/health" || failed=1
check "Margin App" "${MARGIN_APP_URL:-}" || failed=1
check "Catalog App" "${CATALOG_APP_URL:-}" || failed=1

exit "$failed"
