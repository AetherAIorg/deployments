#!/usr/bin/env bash
# Run after https://github.com/AetherAIorg/aether_org exists and main is pushed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if git ls-remote https://github.com/AetherAIorg/aether_org.git HEAD >/dev/null 2>&1; then
  echo "aether_org remote OK"
else
  echo "error: create https://github.com/AetherAIorg/aether_org and push main first" >&2
  exit 1
fi

if [[ -d app/.git ]] || [[ -f app/.git ]]; then
  echo "submodule app/ already exists"
else
  git submodule add https://github.com/AetherAIorg/aether_org.git app
  git commit -m "Add aether_org submodule"
fi

git push origin main
echo "done — deployments repo wired to aether_org"
