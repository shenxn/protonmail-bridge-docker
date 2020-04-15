#!/bin/bash

set -x

DEB_URL=https://protonmail.com/download/protonmail-bridge_1.2.6-1_amd64.deb

# Install tools
apt-get update
apt-get install -y wget binutils xz-utils

# Download deb
mkdir /protonmail
cd /protonmail
wget -O /protonmail/protonmail.deb ${DEB_URL}

# Remove unnecessary dependencies
ar x -v protonmail.deb
mkdir control
tar xvfJ control.tar.xz -C control
cd control
sed -i "s/^Depends: .*$/Depends: libsecret-1-0/" control
tar cvfJ ../control.tar.xz .
cd ../
ar rcs -v protonmail.deb debian-binary control.tar.xz data.tar.xz
