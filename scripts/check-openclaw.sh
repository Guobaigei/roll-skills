#!/usr/bin/env bash

set -u

probe_models=0
if [[ "${1:-}" == "--probe-models" ]]; then
  probe_models=1
fi

has_error=0

add_check() {
  local name="$1"
  local status="$2"
  local detail="$3"

  if [[ "$status" == "ERROR" ]]; then
    has_error=1
  fi

  printf '%-18s %-6s %s\n' "$name" "$status" "$detail"
}

capture() {
  local output
  output="$("$@" 2>&1)"
  local exit_code=$?
  printf '%s\n%d' "$output" "$exit_code"
}

command_path() {
  command -v "$1" 2>/dev/null || true
}

check_command() {
  local name="$1"
  local version_arg="${2:---version}"
  local path
  path="$(command_path "$name")"

  if [[ -z "$path" ]]; then
    add_check "$name" "ERROR" "command not found"
    return 1
  fi

  local raw exit_code output
  raw="$(capture "$path" "$version_arg")"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"

  if [[ "$exit_code" != "0" ]]; then
    add_check "$name" "ERROR" "installed but failed: $output"
    return 1
  fi

  add_check "$name" "OK" "$output"
  return 0
}

check_command "node"
node_path="$(command_path node)"
if [[ -n "$node_path" ]]; then
  node_version="$("$node_path" --version 2>/dev/null || true)"
  node_core="${node_version#v}"
  node_major="${node_core%%.*}"
  if [[ -n "$node_major" && "$node_major" =~ ^[0-9]+$ ]]; then
    if (( node_major < 22 )); then
      add_check "node-version" "ERROR" "Node $node_version is too old; need 22+"
    elif (( node_major != 24 )); then
      add_check "node-version" "WARN" "Node $node_version is supported, but Node 24 is recommended"
    else
      add_check "node-version" "OK" "Node $node_version"
    fi
  else
    add_check "node-version" "WARN" "unable to parse node version"
  fi
fi

check_command "npm"

openclaw_path="$(command_path openclaw)"
if [[ -z "$openclaw_path" ]]; then
  add_check "openclaw" "ERROR" "CLI not found; install via npm workflow first"
else
  openclaw_version="$(capture "$openclaw_path" --version)"
  openclaw_exit="${openclaw_version##*$'\n'}"
  openclaw_output="${openclaw_version%$'\n'*}"
  if [[ "$openclaw_exit" == "0" ]]; then
    add_check "openclaw" "OK" "$openclaw_output"
  else
    add_check "openclaw" "ERROR" "$openclaw_output"
  fi
fi

env_file="$HOME/.openclaw/.env"
if [[ -f "$env_file" ]]; then
  add_check "env-file" "OK" "$env_file"
else
  add_check "env-file" "WARN" "missing $env_file"
fi

config_file="$HOME/.openclaw/openclaw.json"
if [[ -f "$config_file" ]]; then
  add_check "config-file" "OK" "$config_file"
else
  add_check "config-file" "WARN" "missing $config_file"
fi

if [[ -n "$openclaw_path" ]]; then
  raw="$(capture "$openclaw_path" config file)"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"
  if [[ "$exit_code" == "0" ]]; then
    add_check "config-active" "OK" "$output"
  else
    add_check "config-active" "WARN" "$output"
  fi

  raw="$(capture "$openclaw_path" doctor --non-interactive)"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"
  if [[ "$exit_code" == "0" ]]; then
    add_check "doctor" "OK" "doctor completed without a hard failure"
  else
    add_check "doctor" "WARN" "$(printf '%s' "$output" | tr '\n' ' ')"
  fi

  raw="$(capture "$openclaw_path" gateway status)"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"
  if [[ "$exit_code" == "0" ]]; then
    add_check "gateway-status" "OK" "$(printf '%s' "$output" | tr '\n' ' ')"
  else
    add_check "gateway-status" "WARN" "$(printf '%s' "$output" | tr '\n' ' ')"
  fi

  raw="$(capture "$openclaw_path" health)"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"
  if [[ "$exit_code" == "0" ]]; then
    add_check "health" "OK" "health command succeeded"
  else
    add_check "health" "WARN" "$(printf '%s' "$output" | tr '\n' ' ')"
  fi

  raw="$(capture "$openclaw_path" models status --plain)"
  exit_code="${raw##*$'\n'}"
  output="${raw%$'\n'*}"
  if [[ "$exit_code" == "0" ]]; then
    add_check "models-status" "OK" "models status available"
  else
    add_check "models-status" "WARN" "$(printf '%s' "$output" | tr '\n' ' ')"
  fi

  if (( probe_models == 1 )); then
    raw="$(capture "$openclaw_path" models status --probe)"
    exit_code="${raw##*$'\n'}"
    output="${raw%$'\n'*}"
    if [[ "$exit_code" == "0" ]]; then
      add_check "models-probe" "OK" "live provider probe succeeded"
    else
      add_check "models-probe" "WARN" "$(printf '%s' "$output" | tr '\n' ' ')"
    fi
  fi
fi

if command -v nc >/dev/null 2>&1; then
  if nc -z 127.0.0.1 18789 >/dev/null 2>&1; then
    add_check "port-18789" "OK" "127.0.0.1:18789 reachable"
  else
    add_check "port-18789" "WARN" "127.0.0.1:18789 not reachable"
  fi
fi

if (( has_error == 1 )); then
  exit 1
fi
