#!/bin/bash
set -euo pipefail

NIX_SHELL_PATH=/nix/var/nix/profiles/default/bin/nix-shell

if ! command -v "$NIX_SHELL_PATH" &>/dev/null; then
    echo "warning: Nix is not installed. Skipping building Wine."
    exit 0
fi

exec "$NIX_SHELL_PATH" \
    --argstr darwinMinVersion "${MACOSX_DEPLOYMENT_TARGET:-13.5}" \
    --run 'fixupCFlagsForDarwin && ./build-wine.sh'
