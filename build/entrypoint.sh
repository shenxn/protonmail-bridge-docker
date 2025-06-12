#!/bin/bash

set -ex

if [[ $1 == init ]]; then
    echo "The init command is deprecated. Go to our github repo for setup instructions."
fi

if [[ $HOME == "/" ]] then
    echo "When running rootless, you must set a home dir as the HOME env var. We recommend /data. Make sure it is writable by the user running the container (currently id is $(id -u) and HOME is $HOME)."
    exit 1
fi

# give friendly error if you don't have protonmail data
if [[ `find $HOME | wc -l` == 1 ]]; then # 1 because find $HOME will always return $HOME
    echo 'Protonmail does not seem to have been initialized yet. Enter the container with something like `docker exec -it <container_name>` and type "help" for instructions on how to set up the ProtonMail Bridge'
    timeout 10s /protonmail/proton-bridge --noninteractive # this starts the bridge in non-interactive mode and kills it after 20 seconds, so we can populate the vault with default values and override them with the env variables in the later step.
fi

# give friendly error if the user doesn't own the data
if [[ $(id -u) != 0 ]]; then
    if [[ `find $HOME/.* -not -user $(id -u) | wc -l` != 0 ]]; then
        echo "You do not own the data in $HOME. Please chown it to $(id -u), run the container as the owner of the data or run the container as root."
        exit 1
    fi
fi

if [[ ! -f $HOME/.gnupg ]]; then
    echo "No GPG key found in $HOME/.gnupg. Running gpg --generate-key."
    gpg --generate-key --batch /protonmail/gpgparams
    pass init pass-key
fi
# delete lock files if they exist - this can happen if the container is restarted forcefully

if [[ `find $HOME -name "*.lock" | wc -l` != 0 ]]; then
    echo "Deleting lock files in $HOME. This can happen if the container is restarted forcefully."
    find $HOME -name "*.lock" -delete
fi

# socat will make the conn appear to come from 127.0.0.1
# ProtonMail Bridge currently expects that.
# It also allows us to bind to the real ports :)
if [[ $(id -u) == 0 ]]; then
    socat TCP-LISTEN:25,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:143,fork TCP:127.0.0.1:1143 &
else
    socat TCP-LISTEN:2025,fork TCP:127.0.0.1:1025 &
    socat TCP-LISTEN:2143,fork TCP:127.0.0.1:1143 &
fi

# Broken until https://github.com/ProtonMail/proton-bridge/issues/512 is resolved.
# check if the vault-editor can read the config
/protonmail/vault-editor read 2>&1 1>/dev/null
# Modify the protonmail config with env variables and expected values. Env variables must be converted from string to boolean.
/protonmail/vault-editor read | \
jq '.Settings.AutoUpdate = (env.PROTONMAIL_AutoUpdate | if . == "true" then true else false end)
| .Settings.TelemetryDisabled = (env.PROTONMAIL_TelemetryDisabled | if . == "true" then true else false end)
| .Settings.GluonDir |= "\(env.HOME)/.local/share/protonmail/bridge-v3/gluon"
| .Settings.Autostart = false
| .Settings.SMTPPort = 1025
| .Settings.IMAPPort = 1143 ' \
| /protonmail/vault-editor write

# Start protonmail
echo "Starting ProtonMail Bridge. Connect to the CLI with `docker exec -it <container_name>` and type 'help' for instructions."
/protonmail/proton-bridge --cli $@
