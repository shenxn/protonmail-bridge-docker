#!/bin/bash

set -ex

source /protonmail/releaserc

# Install dependents
apt-get update
apt-get install -y --no-install-recommends socat pass

# Download repacked deb
apt-get install -y wget
wget -O /protonmail/protonmail.deb https://github.com/shenxn/protonmail-bridge-docker/releases/download/${RELEASE}/${DEB_FILE}
apt-get purge -y wget
apt-get autoremove -y

# Install protonmail bridge
apt-get install -y --no-install-recommends /protonmail/protonmail.deb

# Cleanup
rm -rf /var/lib/apt/lists/*
rm /protonmail/protonmail.deb
