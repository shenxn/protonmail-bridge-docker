#!/bin/bash

set -ex

source ./releaserc

git config --local user.email "actions@github.com"
git config --local user.name "Github Action"
git tag -a "r${RELEASE}" -m "Release ${RELEASE}"
REMOTE_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git push "${REMOTE_REPO}" "r${RELEASE}"
