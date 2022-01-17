#!/bin/bash 

cd $TMPDIR
export PATH=$WINEPATH:$PATH
echo $WINEPATH
rm master.zip
rm -rf gshade_installer-master
curl -LO https://github.com/HereInPlainSight/gshade_installer/archive/refs/heads/master.zip
unzip -qquo master.zip
cd gshade_installer-master
./gshade_installer.sh
