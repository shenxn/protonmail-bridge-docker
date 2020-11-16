#!/bin/bash

set -ex

VERSION=`cat VERSION`

if [[ $GITHUB_REF == "refs/heads/master" ]]; then
    echo "TAGS=latest,${VERSION}" >> $GITHUB_ENV
else
    echo "TAGS=dev,${VERSION}-dev" >> $GITHUB_ENV
fi
