#!/bin/bash

set -ex

# Initialize
if [[ $1 == init ]]; then

    # # Parse parameters
    # TFP=""  # Default empty two factor passcode
    # shift  # skip `init`
    # while [[ $# -gt 0 ]]; do
    #     key="$1"
    #     case $key in
    #         -u|--username)
    #         USERNAME="$2"
    #         ;;
    #         -p|--password)
    #         PASSWORD="$2"
    #         ;;
    #         -t|--twofactor)
    #         TWOFACTOR="$2"
    #         ;;
    #     esac
    #     shift
    #     shift
    # done

    # Initialize pass
    gpg --generate-key --batch /protonmail/gpgparams
    pass init pass-key

    # Login
    protonmail-bridge --cli $@

else
    if [[ $HOME == "/" ]] then
        echo "When running rootless, you must set a home dir as the HOME env var. We recommend /data. Make sure it is writable by the user running the container (currently id is $(id -u) and HOME is $HOME)."
        exit 1
    fi

    # give friendly error if you don't have protonmail data
    if [[ `find $HOME | wc -l` == 1 ]]; then # 1 because find $HOME will always return $HOME
        echo "No files found - start the container with the init command, or copy/mount files into it at $HOME first. Sleeping 5 minutes before exiting so you have time to copy the files over."
        sleep 300
        exit 1
    fi

    # give friendly error if the user doesn't own the data
    if [[ $(id -u) != 0 ]]; then
        if [[ `find $HOME/.* -not -user $(id -u) | wc -l` != 0 ]]; then
          echo "You do not own the data in $HOME. Please chown it to $(id -u), run the container as the owner of the data or run the container as root."
          exit 1
        fi
    fi

    # delete lock files if they exist - this can happen if the container is restarted forcefully
    find $HOME -name "*.lock" -delete

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
