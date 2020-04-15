# ProtonMail IMAP/SMTP Bridge Docker Container

This is an unofficial Docker container of the [ProtonMail Bridge](https://protonmail.com/bridge/). Some of the scripts are based on [Hendrik Meyer's work](https://gitlab.com/T4cC0re/protonmail-bridge-docker).

## Initialization

To initialize and add account to the bridge, run the following command.

```
docker run --rm -it -v protonmail:/root shenxn/protonmail-bridge init
```

Wait for the bridge to startup, use `login` command and follow the instructions to add your account into the bridge. Then use `info` to see the configuration information (username and password). After that, use `exit` to exit the bridge. You may need `CTRL+C` to exit the docker entirely.


## Run

To run the container, use the following command.

```
docker run -d --name=protonmail-bridge -v protonmail:/root -p 1025:25/tcp -p 1143:143/tcp --restart=unless-stopped shenxn/protonmail-bridge
```


## Compatability

The bridge currently only supports some of the email clients and can only run on `amd64` architecture. More details can be found on the official website. I've tested this on a Synology DiskStation and it runs well. However, you may need ssh onto it to run the interactive docker command to add your account. The main reason of using this instead of environment variables is that it seems to be the best way to support two-factor authentication.
