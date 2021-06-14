#!/bin/bash

set -ex

# Initialize
if [[ $1 == init ]]; then
    # set GNUPGHOME as a workaround for
    #
    #   gpg-agent[106]: error binding socket to '/root/.gnupg/S.gpg-agent': File name too long
    #
    # when using docker volume mount
    #
    # ref: https://dev.gnupg.org/T2964
    #

    export GNUPGHOME="${GNUPGHOME:-"/tmp/gnupg"}"
    rm -rf "${GNUPGHOME}" || true
    mkdir -p "${GNUPGHOME}"
    chmod 0700 "${GNUPGHOME}"

    # Initialize pass
    gpg --generate-key --batch /protonmail/gpgparams
    pass init "${MASTER_PASSWORD:-"pass-key"}"

    # Login
    do_login="/protonmail/proton-bridge --cli $*"
    if [[ "x${PROTONMAIL_USERNAME}" != "x" && "x${PROTONMAIL_PASSWORD}" != "x" ]]; then
        # automated login if both username and password are set
        do_login="/protonmail/login.exp ${do_login}"
    fi

    $do_login

    # copy gnupg files to default path
    mkdir -p /root/.gnupg
    kill "$(pidof gpg-agent)"
    cp -a "${GNUPGHOME}/" /root/.gnupg/

else

    # socat will make the conn appear to come from 127.0.0.1
    # ProtonMail Bridge currently expects that.
    # It also allows us to bind to the real ports :)
    socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &

    # Start protonmail
    # Fake a terminal, so it does not quit because of EOF...
    rm -f faketty
    mkfifo faketty
    cat faketty | /protonmail/proton-bridge --cli $@

fi
