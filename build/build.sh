#!/bin/bash

set -ex

VERSION=`cat VERSION`

# Clone new code
git clone https://github.com/ProtonMail/proton-bridge.git
cd proton-bridge
git checkout $VERSION

# Enable debug log
sed -i "s/build desktop/-debug build desktop/" Makefile

# Build
make build-nogui
