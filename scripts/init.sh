#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .gitmodules ]]; then
  echo "error: .gitmodules not found — run from deployments repo root" >&2
  exit 1
fi

echo "Initializing submodule app/ → aether_org ..."
git submodule update --init --recursive

if [[ ! -d app/.git ]]; then
  echo ""
  echo "Submodule empty. Update .gitmodules with your aether_org remote, then:"
  echo "  git submodule add git@github.com:YOUR_ORG/aether_org.git app"
  exit 1
fi

echo "Submodule ready at: $(git -C app rev-parse --short HEAD)"
