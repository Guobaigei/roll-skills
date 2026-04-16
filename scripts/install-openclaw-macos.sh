#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${1:-$SKILL_DIR/.env}"

ensure_path() {
  for dir in /opt/homebrew/bin /usr/local/bin; do
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
    fi
  done
}

node_ok() {
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi

  local major
  major="$(node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || echo 0)"
  [[ "$major" =~ ^[0-9]+$ ]] || return 1
  (( major >= 22 ))
}

install_node() {
  echo "Node not found or too old. Installing Node..."
  if command -v brew >/dev/null 2>&1; then
    brew install node@24
    brew link --overwrite --force node@24 || true
    ensure_path
    return
  fi

  local version pkg_url pkg_path
  version="$(curl -fsSL https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt | awk '/\.pkg$/ {print $2; exit}')"
  if [[ -z "$version" ]]; then
    echo "Failed to resolve latest Node 24 pkg."
    exit 1
  fi

  pkg_url="https://nodejs.org/dist/latest-v24.x/$version"
  pkg_path="/tmp/$version"
  curl -fsSL "$pkg_url" -o "$pkg_path"
  sudo installer -pkg "$pkg_path" -target /
  ensure_path
}

ensure_path

if ! node_ok; then
  install_node
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "env file not found: $ENV_FILE"
  exit 1
fi

npm install -g openclaw@latest
node "$SCRIPT_DIR/apply-openclaw-config.mjs" --env-file "$ENV_FILE"

if ! openclaw gateway install; then
  echo "gateway install skipped or already installed; continuing"
fi

if ! openclaw gateway start; then
  openclaw gateway restart
fi

openclaw gateway status
openclaw health --verbose || true
openclaw dashboard
