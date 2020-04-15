#!/bin/bash

set -x

# Install dependents
# libgl1-mesa-glx is installed since the bridge requires libgl and we removed the qt dependencies
apt-get update
apt-get install -y --no-install-recommends socat pass libgl1-mesa-glx

# Install protonmail bridge
apt-get install -y --no-install-recommends /protonmail/protonmail.deb

# Cleanup
rm -rf /var/lib/apt/lists/*
rm /protonmail/protonmail.deb
