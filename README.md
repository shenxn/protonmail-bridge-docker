# ProtonMail IMAP/SMTP Bridge Docker Container

![version badge](https://img.shields.io/docker/v/shenxn/protonmail-bridge)
![image size badge](https://img.shields.io/docker/image-size/shenxn/protonmail-bridge/build)
![docker pulls badge](https://img.shields.io/docker/pulls/shenxn/protonmail-bridge)
![build badge](https://github.com/shenxn/protonmail-bridge-docker/workflows/.github/workflows/main.yaml/badge.svg)

This is an unofficial Docker container of the [ProtonMail Bridge](https://protonmail.com/bridge/). Some of the scripts are based on [Hendrik Meyer's work](https://gitlab.com/T4cC0re/protonmail-bridge-docker).

Docker Hub: [https://hub.docker.com/r/shenxn/protonmail-bridge](https://hub.docker.com/r/shenxn/protonmail-bridge)

GitHub: [https://github.com/shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker)

## ARM Support

We now support ARM devices (arm64 and arm/v7)! Use the images tagged with `build`. See next section for details.

## Tags

tag | description
 -- | --
`latest` | latest image based on [.deb release](https://protonmail.com/bridge/install)
`[version]` | images based on .deb release
`build` | latest image built from [source](https://github.com/ProtonMail/proton-bridge)
`[version]-build` | images built from source
`dev`, `[version]-dev`, `[version]-build-dev` | images built from dev branch (not recommend)

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

## Kubernetes

If you want to run this image in a Kubernetes environment, [#6](https://github.com/shenxn/protonmail-bridge-docker/issues/6) can be helpful.

## Compatability

The bridge currently only supports some of the email clients. More details can be found on the official website. I've tested this on a Synology DiskStation and it runs well. However, you may need ssh onto it to run the interactive docker command to add your account. The main reason of using this instead of environment variables is that it seems to be the best way to support two-factor authentication.
