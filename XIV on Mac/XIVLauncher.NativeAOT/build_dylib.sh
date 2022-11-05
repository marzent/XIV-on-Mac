#!/bin/zsh

set -x

pushd source/src/XIVLauncher.NativeAOT
dotnet publish -r osx-x64 -c release 
dotnet publish -p:BuildForArm64=true -r osx-arm64 -c release
popd

lipo -create source/src/XIVLauncher.NativeAOT/bin/release/net7.0/osx-arm64/publish/XIVLauncher.NativeAOT.dylib source/src/XIVLauncher.NativeAOT/bin/release/net7.0/osx-x64/publish/XIVLauncher.NativeAOT.dylib -output XIVLauncher.NativeAOT.dylib
cp source/src/XIVLauncher.NativeAOT/bin/release/net7.0/osx-arm64/publish/libsteam_api64.dylib .

install_name_tool -id @executable_path/../Frameworks/XIVLauncher.NativeAOT.dylib XIVLauncher.NativeAOT.dylib
install_name_tool -id @executable_path/../Frameworks/libsteam_api64.dylib libsteam_api64.dylib
