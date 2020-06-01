#!/bin/bash

set -ex

# Enter the right path
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
cd $SCRIPTPATH

# Set docker tag
VERSION=`cat VERSION`
if [[ $GITHUB_REF == "refs/heads/master" ]]; then
    TAG_TYPE="build"
    TAG_VERTION="${VERSION}-build"
else
    TAG_TYPE="build-dev"
    TAG_VERTION="${VERSION}-build-dev"
fi

# Build multiarch and push
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6 -t ${DOCKER_REPO}:${TAG_TYPE} -t ${DOCKER_REPO}:${TAG_VERSION} --push .
