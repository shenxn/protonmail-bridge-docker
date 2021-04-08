#!/bin/bash

set -ex

VERSION=`cat VERSION`
DEB_FILE=protonmail-bridge_${VERSION}_amd64.deb

# Install dependents
apt-get update
apt-get install -y --no-install-recommends socat pass ca-certificates

# Build time dependencies
apt-get install -y wget binutils xz-utils

# Repack deb (remove unnecessary dependencies)
mkdir deb
cd deb
wget -q https://protonmail.com/download/bridge/${DEB_FILE}
ar x -v ${DEB_FILE}
mkdir control
tar zxvf control.tar.gz -C control
sed -i "s/^Depends: .*$/Depends: libgl1, libc6, libsecret-1-0, libstdc++6, libgcc1/" control/control
cd control
tar zcvf ../control.tar.gz .
cd ../
ar rcs -v ${DEB_FILE} debian-binary control.tar.gz data.tar.gz
cd ../

# Install protonmail bridge
apt-get install -y --no-install-recommends ./deb/${DEB_FILE}

# Cleanup
apt-get purge -y wget binutils xz-utils
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
rm -rf deb
