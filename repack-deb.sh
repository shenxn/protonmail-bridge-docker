#!/bin/bash

set -ex

source releaserc

# Download deb
mkdir deb
cd deb
rm -f ${DEB_FILE}
wget https://protonmail.com/download/${DEB_FILE}

# Unpack deb
ar x -v ${DEB_FILE}
mkdir control
tar xvfJ control.tar.xz -C control

# Replace qt with libgl and remove unnecessary dependencies
sed -i "s/^Depends: .*$/Depends: libsecret-1-0, libgl1-mesa-glx/" control/control

# Pack deb
cd control
tar cvfJ ../control.tar.xz .
cd ../
ar rcs -v ${DEB_FILE} debian-binary control.tar.xz data.tar.xz
