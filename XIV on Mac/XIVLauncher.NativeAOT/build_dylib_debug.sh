#!/bin/zsh

set -x

export MACOSX_DEPLOYMENT_TARGET=11.0
pushd source/src/XIVLauncher.NativeAOT
dotnet publish -r osx-x64 -c debug
dotnet publish -r osx-arm64 -c debug
popd

lipo -create source/src/XIVLauncher.NativeAOT/bin/debug/net8.0/osx-arm64/publish/XIVLauncher.NativeAOT.dylib source/src/XIVLauncher.NativeAOT/bin/debug/net8.0/osx-x64/publish/XIVLauncher.NativeAOT.dylib -output XIVLauncher.NativeAOT.dylib
cp source/src/XIVLauncher.NativeAOT/bin/debug/net8.0/osx-arm64/publish/libsteam_api64.dylib .

install_name_tool -id @executable_path/../Frameworks/XIVLauncher.NativeAOT.dylib XIVLauncher.NativeAOT.dylib
install_name_tool -id @executable_path/../Frameworks/libsteam_api64.dylib libsteam_api64.dylib
