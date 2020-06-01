#!/bin/bash

set -ex

REMOTE_REPO="https://${GITHUB_ACTOR}:${PERSONAL_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

VERSION=`cat VERSION`

JSON_CONTENT=$(curl -q https://protonmail.com/download/current_version_linux.json)
URL=$(echo ${JSON_CONTENT} | sed -n "s/^.*\"DebFile\":\"\([a-z0-9:/._-]*\)\".*$/\1/p")
CURR_VERSION=$(echo $URL | sed -n "s/https:\/\/protonmail.com\/download\/protonmail-bridge_\([0-9.-]*\)_amd64.deb/\1/p")

if [[ $VERSION != $CURR_VERSION ]]; then
    echo "New release found: ${CURR_VERSION}"

    # bump up to new release
    cat ${CURR_VERSION} > VERSION

    # commit
    git config --local user.email "actions@github.com"
    git config --local user.name "Github Action"
    git add VERSION
    git commit -m "Bump version to ${CURR_VERSION}" --author="Xiaonan Shen <s@sxn.dev>"

    # push
    git push "${REMOTE_REPO}" master

    # # trigger actions
    # curl -H "Accept: application/vnd.github.everest-preview+json" \
    #     -H "Authorization: token ${PERSONAL_TOKEN}" \
    #     --request POST \
    #     --data '{"event_type": "build"}' \
    #     https://api.github.com/repos/${GITHUB_REPOSITORY}/dispatches
fi
