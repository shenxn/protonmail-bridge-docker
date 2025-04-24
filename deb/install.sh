#!/bin/bash
set -ex

# Repack deb (remove unnecessary dependencies)
mkdir deb
wget -i /PACKAGE -O /deb/protonmail.deb
cd deb
ar x -v protonmail.deb
mkdir control
tar zxvf control.tar.gz -C control
sed -i "s/^Depends: .*$/Depends: libgl1, libc6, libsecret-1-0, libstdc++6, libgcc1/" control/control
cd control
tar zcvf ../control.tar.gz .
cd ../

ar rcs -v /protonmail.deb debian-binary control.tar.gz data.tar.gz
