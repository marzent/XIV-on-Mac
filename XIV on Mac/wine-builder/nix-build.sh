#!/bin/bash
#set -x

NIX_BUID_PATH=/nix/var/nix/profiles/default/bin/nix-build

if ! command -v $NIX_BUID_PATH &>/dev/null; then
    echo "warning: Nix is not installed. Skipping building Wine."
    exit 0
fi

$NIX_BUID_PATH --max-jobs $(sysctl -n hw.ncpu) --argstr darwinMinVersion "$MACOSX_DEPLOYMENT_TARGET"
