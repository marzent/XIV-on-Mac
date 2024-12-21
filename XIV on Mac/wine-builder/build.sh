#!/bin/bash

export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-12.0}
./nix-build.sh
./package-runtime.sh
