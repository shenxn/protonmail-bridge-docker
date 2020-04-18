#!/bin/bash

set -ex

REMOTE_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Switch to master branch
git clone "${REMOTE_REPO}" master
cd master

source ./releaserc

JSON_CONTENT=$(curl -q https://protonmail.com/download/current_version_linux.json)
URL=$(echo ${JSON_CONTENT} | sed -n "s/^.*\"DebFile\":\"\([a-z0-9:/._-]*\)\".*$/\1/p")
CURR_RELEASE=$(echo $URL | sed -n "s/https:\/\/protonmail.com\/download\/protonmail-bridge_\([0-9.-]*\)_amd64.deb/\1/p")

if [[ $RELEASE != $CURR_RELEASE ]]; then
    echo "New release found: ${CURR_RELEASE}"

    # bump up to new release
    sed -i "s/^RELEASE=.*$/RELEASE=${CURR_RELEASE}/" releaserc

    # commit
    git config --local user.email "actions@github.com"
    git config --local user.name "Github Action"
    git add releaserc
    git commit -m "Release ${CURR_RELEASE}" --author="Xiaonan Shen <s@sxn.dev>"
    git tag -a "v${CURR_RELEASE}" -m "Release ${CURR_RELEASE}"

    # push
    git push "${REMOTE_REPO}" master
    git push "${REMOTE_REPO}" master --tags

    # trigger actions
    curl -H "Accept: application/vnd.github.everest-preview+json" \
        -H "Authorization: token ${PERSONAL_TOKEN}" \
        --request POST \
        --data '{"event_type": "build"}' \
        https://api.github.com/repos/${GITHUB_REPOSITORY}/dispatches
fi
