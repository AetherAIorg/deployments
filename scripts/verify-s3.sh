#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${S3_BUCKET:-}" || -z "${S3_ACCESS_KEY:-}" || -z "${S3_SECRET_KEY:-}" ]]; then
  echo "Set S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY to verify storage."
  exit 0
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not installed — skipping S3 verify."
  exit 0
fi

endpoint_args=()
if [[ -n "${S3_ENDPOINT:-}" ]]; then
  endpoint_args+=(--endpoint-url "$S3_ENDPOINT")
fi

echo "listing s3://${S3_BUCKET} ..."
AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY" AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY" \
  aws s3 ls "s3://${S3_BUCKET}" "${endpoint_args[@]}"
echo "S3 bucket reachable."
