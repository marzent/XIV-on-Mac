#!/bin/bash 

cd $TMPDIR
export PATH=$WINEPATH:$PATH
rm master.zip &>/dev/null
rm -rf gshade_installer-master &>/dev/null
curl -LO https://github.com/HereInPlainSight/gshade_installer/archive/refs/heads/master.zip
unzip -qquo master.zip
cd gshade_installer-master
./gshade_installer.sh
