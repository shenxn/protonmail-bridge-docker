#!/bin/bash

set -e

if [ -z "$KEYRING_PASSPHRASE" ]; then
    echo "KEYRING_PASSPHRASE cannot be empty"
    exit 1
fi

gpg_present_phrase () {
    /usr/lib/gnupg2/gpg-preset-passphrase -P "$KEYRING_PASSPHRASE" \
      -c "$(basename "$HOME"/.gnupg/private-keys-v1.d/*.key .key)"
}

# Start gpg-agent to force allow presetting passphrase
gpg-agent --homedir "$HOME"/.gnupg --daemon --allow-preset-passphrase

# Initialize
if [[ $1 == init ]]; then

    # Initialize GPG if no private key
    # While -f can't handle globs, only one key can be generated
    if [ ! -f "$HOME"/.gnupg/private-keys-v1.d/*.key ]; then
      gpg --generate-key --passphrase "$KEYRING_PASSPHRASE" --pinentry-mode loopback \
        --batch /protonmail/gpgparams
    fi

    # Initialize pass if no password-store
    if [ ! -d "$HOME"/.password-store ]; then
      pass init pass-key
    fi

    gpg_present_phrase

    # Kill the other instance as only one can be running at a time.
    # This allows users to run entrypoint init inside a running conainter
    # which is useful in a k8s environment.
    # || true to make sure this would not fail in case there is no running instance.
    pkill protonmail-bridge || true

    # Login
    protonmail-bridge --cli

else
    # Load passphrase into gpg-agent
    gpg_present_phrase

    # socat will make the conn appear to come from 127.0.0.1
    # ProtonMail Bridge currently expects that.
    # It also allows us to bind to the real ports :)
    socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &

    # Start protonmail
    # Fake a terminal, so it does not quit because of EOF...
    rm -f faketty
    mkfifo faketty
    cat faketty | protonmail-bridge --cli

fi
