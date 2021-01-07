#!/bin/bash

set -ex

VERSION=`cat VERSION`

# Clone new code
git clone https://github.com/ProtonMail/proton-bridge.git
cd proton-bridge
git checkout br-$VERSION

# Build
make build-nogui
