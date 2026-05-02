#!/usr/bin/env bash
# require-sudo.sh — ensure sudo is active, prompt only if needed.
# Usage: source ./require-sudo.sh

# Guard against being sourced twice
[[ -n "${__SUDO_READY:-}" ]] && return 0 2>/dev/null || true

# Must be sourced, not executed (otherwise the keep-alive dies with the subshell)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script must be sourced, not executed: source ${BASH_SOURCE[0]}" >&2
    exit 1
fi

# Check for sudo binary
if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is not installed." >&2
    return 1
fi

# If sudo timestamp is still valid, no prompt; otherwise ask for password
if sudo -n true 2>/dev/null; then
    echo "==> sudo already active."
else
    echo "==> sudo required. Please enter your password."
    if ! sudo -v; then
        echo "Error: failed to obtain sudo." >&2
        return 1
    fi
fi

# Keep sudo alive in the background until the parent script exits
( while true; do
      sudo -n true 2>/dev/null || exit
      sleep 60
      kill -0 "$PPID" 2>/dev/null || exit
  done ) &
__SUDO_KEEPER_PID=$!

# Clean up the keep-alive on exit (only set trap once)
trap 'kill "$__SUDO_KEEPER_PID" 2>/dev/null || true' EXIT

export __SUDO_READY=1