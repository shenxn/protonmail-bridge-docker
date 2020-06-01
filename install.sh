#!/bin/bash

set -ex

VERSION=`cat VERSION`
DEB_FILE=protonmail-bridge_${VERSION}_amd64.deb

# Install dependents
apt-get update
apt-get install -y --no-install-recommends socat pass

# Build time dependencies
apt-get install -y wget binutils xz-utils

# Repack deb (remove unnecessary dependencies)
wget https://protonmail.com/download/${DEB_FILE}
ar x -v ${DEB_FILE}
mkdir control
tar xvfJ control.tar.xz -C control
sed -i "s/^Depends: .*$/Depends: libsecret-1-0, libgl1-mesa-glx/" control/control
cd control
tar cvfJ ../control.tar.xz .
cd ../
ar rcs -v ${DEB_FILE} debian-binary control.tar.xz data.tar.xz

# Install protonmail bridge
apt-get install -y --no-install-recommends ./${DEB_FILE}

# Cleanup
apt-get purge -y wget binutils xz-utils
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
rm ${DEB_FILE}
