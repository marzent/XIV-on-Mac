#!/bin/bash 

cd $TMPDIR
export PATH=$WINEPATH:$PATH
export WINEESYNC=1
export WINEPREFIX="$HOME/Library/Application Support/XIV on Mac/game"
rm -rf gshade_installer
git clone https://github.com/HereInPlainSight/gshade_installer.git
cd gshade_installer
./gshade_installer.sh ffxiv
