#!/bin/bash 

cd $TMPDIR
export PATH=$WINEPATH:$PATH
rm master.zip &>/dev/null
rm -rf gshade_installer-master &>/dev/null
curl -LO https://github.com/HereInPlainSight/gshade_installer/archive/refs/heads/master.zip
unzip -qquo master.zip
cd gshade_installer-master
if [[ -z "${GSHADE_FORCE_UPDATE}" ]]; then
  ./gshade_installer.sh
else
  ./gshade_installer.sh update force
fi
