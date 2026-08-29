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
    tmux new-session -d -s bridge-init "/protonmail/proton-bridge --cli $@"
    echo "ProtonMail Bridge init running inside tmux session 'bridge-init'"
    echo "Attach with: docker exec -it <container> tmux attach -t bridge-init"

    sleep infinity

else

    # socat will make the conn appear to come from 127.0.0.1
    # ProtonMail Bridge currently expects that.
    # It also allows us to bind to the real ports :)
    socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &

    tmux new-session -d -s bridge "/protonmail/proton-bridge --cli $@"
    echo "ProtonMail Bridge running inside tmux session 'bridge'"
    echo "Attach with: docker exec -it <container> tmux attach -t bridge"

    sleep infinity

fi
