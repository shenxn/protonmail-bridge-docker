#!/bin/bash

set -ex

IS_PULL_REQUEST=$1


check_version() {
    DIR=$1
    CURR_VERSION=$2

    echo "Checking version for ${DIR}"

    VERSION=`cat ${DIR}/VERSION`

    if [[ -z $CURR_VERSION ]]; then
        echo "Failed to get new version. Existing."
        exit 1
    fi

    if [[ $VERSION != $CURR_VERSION ]]; then
        echo "New release found: ${CURR_VERSION}"

        if [[ $IS_PULL_REQUEST == "true" ]]; then
            echo "Action triggered by pull request. Do not bump version."
        else
            # bump up to new release
            echo ${CURR_VERSION} > ${DIR}/VERSION

            # commit
            git config --local user.email "actions@github.com"
            git config --local user.name "Github Action"
            git add ${DIR}/VERSION
            git commit -m "Bump ${DIR} version to ${CURR_VERSION}" --author="Xiaonan Shen <s@sxn.dev>"
            git push
        fi
    else
        echo "Already newest version ${VERSION}"
    fi

}


JSON_CONTENT=$(curl -q https://protonmail.com/download/current_version_linux.json)
URL=$(echo ${JSON_CONTENT} | sed -n "s/^.*\"DebFile\":\"\([a-z0-9:/._-]*\)\".*$/\1/p")
CURR_VERSION=$(echo $URL | sed -n "s/https:\/\/protonmail.com\/.*_\([0-9.-]*\)_.*.deb/\1/p")
check_version deb $CURR_VERSION
