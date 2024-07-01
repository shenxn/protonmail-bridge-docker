#!/bin/bash

set -ex

# Modify prefs.json
if [[ $cache_enabled == "false" ]]; then
    sed -Ei 's/"cache_enabled": ".+"/"cache_enabled": "false"/' /root/.config/protonmail/bridge/prefs.json
    echo "entrypoint.sh: cache disabled"
    echo "- deleting cache.."; rm -rf "/root/.config/protonmail/bridge/cache/*/messages/*" && echo "- .. done!" || echo "- .. failed to delete cache!"
elif [[ $cache_enabled == "true" ]]; then
    sed -Ei 's/"cache_enabled": ".+"/"cache_enabled": "true"/' /root/.config/protonmail/bridge/prefs.json
    echo "entrypoint.sh: cache enabled"
fi

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
