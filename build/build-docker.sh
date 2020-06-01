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
    TAG_VERSION="${VERSION}-build"
else
    TAG_TYPE="build-dev"
    TAG_VERSION="${VERSION}-build-dev"
fi

# Docker login
echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USERNAME}" --password-stdin

# Build multiarch and push
docker buildx build $BUILD_ARGS --platform linux/amd64,linux/arm64/v8,linux/arm/v7 -t ${DOCKER_REPO}:${TAG_TYPE} -t ${DOCKER_REPO}:${TAG_VERSION} --push .
