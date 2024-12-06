#!/bin/bash

set -ex

# Initialize
if [[ $1 == init ]]; then

    # Initialize pass
    gpg --generate-key --batch /protonmail/gpgparams
    pass init pass-key
    
    # Kill the other instance as only one can be running at a time.
    # This allows users to run entrypoint init inside a running conainter
    # which is useful in a k8s environment.
    # || true to make sure this would not fail in case there is no running instance.
    pkill protonmail-bridge || true

    # Login
    /protonmail/proton-bridge --cli $@

else
    # delete lock files if they exist - this can happen if the container is restarted forcefully
    find $HOME -name "*.lock" -delete

    # give friendly error if you don't have protonmail data
    find $HOME | grep -q . || (echo "No files found - start the container with the init command, or copy/mount files into it at $HOME first. Sleeping 5 minutes before exiting so you have time to copy the files over." && sleep 300 && exit 1)
    # give friendly error if the user doesn't own the data
    if [[ $(id -u) != 0 ]]; then
        if [[ `find $HOME/.* -not -user $(id -u) | wc -l` != 0 ]]; then
          echo "You do not own the data in $HOME. Please chown it to $(id -u), run the container as the owner of the data or run the container as root." && exit 1
        fi
    fi

    # socat will make the conn appear to come from 127.0.0.1
    # ProtonMail Bridge currently expects that.
    # It also allows us to bind to the real ports :)
    if [[ $(id -u) == 0 ]]; then
        socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
        socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &
    fi

    socat TCP-LISTEN:2025,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:2143,fork TCP:127.0.0.1:1143 &

    # Start protonmail
    /protonmail/proton-bridge --noninteractive $@

fi
