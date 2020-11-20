#!/bin/bash

set -ex

VERSION=`cat VERSION`

JSON_CONTENT=$(curl -q https://protonmail.com/download/current_version_linux.json)
URL=$(echo ${JSON_CONTENT} | sed -n "s/^.*\"DebFile\":\"\([a-z0-9:/._-]*\)\".*$/\1/p")
CURR_VERSION=$(echo $URL | sed -n "s/https:\/\/protonmail.com\/.*_\([0-9.-]*\)_.*.deb/\1/p")

if [[ -z $CURR_VERSION ]]; then
    echo "Failed to get new version. Existing."
    exit 1
fi

if [[ $VERSION != $CURR_VERSION ]]; then
    echo "New release found: ${CURR_VERSION}"

    # bump up to new release
    echo ${CURR_VERSION} > VERSION

    # commit
    git config --local user.email "actions@github.com"
    git config --local user.name "Github Action"
    git add VERSION
    git commit -m "Bump version to ${CURR_VERSION}" --author="Xiaonan Shen <s@sxn.dev>"
    git push
fi
