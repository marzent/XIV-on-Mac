#!/bin/bash

export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-13.5}
./nix-build.sh
./package-runtime.sh
