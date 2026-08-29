# ProtonMail IMAP/SMTP Bridge Docker Container

![version badge](https://img.shields.io/docker/v/shenxn/protonmail-bridge)
![image size badge](https://img.shields.io/docker/image-size/shenxn/protonmail-bridge/build)
![docker pulls badge](https://img.shields.io/docker/pulls/shenxn/protonmail-bridge)
![deb badge](https://github.com/shenxn/protonmail-bridge-docker/workflows/pack%20from%20deb/badge.svg)
![build badge](https://github.com/shenxn/protonmail-bridge-docker/workflows/build%20from%20source/badge.svg)

This is an unofficial Docker container of the [ProtonMail Bridge](https://protonmail.com/bridge/). Some of the scripts are based on [Hendrik Meyer's work](https://gitlab.com/T4cC0re/protonmail-bridge-docker).

Docker Hub: [https://hub.docker.com/r/shenxn/protonmail-bridge](https://hub.docker.com/r/shenxn/protonmail-bridge)

GitHub: [https://github.com/shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker)

## ARM Support

We now support ARM devices (`arm64` and `arm/v7`)! Use the images tagged with `build`. See next section for details.

## Tags

There are two types of images.
 - `deb`: Images based on the official [.deb release](https://protonmail.com/bridge/install). It only supports the `amd64` architecture.
 - `build`: Images based on the [source code](https://github.com/ProtonMail/proton-bridge). It supports `amd64`, `arm64`, `arm/v7` and `riscv64`. Supporting to more architectures is possible. PRs are welcome.

tag | description
 -- | --
`latest` | latest `deb` image
`[version]` | `deb` images
`build` | latest `build` image
`[version]-build` | `build` images

## Starting the container

To initialize and add account to the bridge, run the following steps:

1. Start the container with a named volume (protonmail) for persistent storage.
```
docker run -it -v protonmail:/root shenxn/protonmail-bridge
```
2. When you are done, press `CTRL+P` followed by `CTRL+Q`. This detaches the container from your terminal and keeps it running in the background.

## Setting up the bridge

If you have not set up an account, you need to do the folliwing steps in the protonmail-bridge CLI interface:
1. Connect to the running container by getting it's name using `docker ps` and then running:
```
docker attach <container_name>
```
2. Use the `add` command to add your ProtonMail account. You will be prompted to enter your ProtonMail username and password.
3. After adding your account, use the `info` command to see the configuration information (username and password).

## Security

Please be aware that running the command above will expose your bridge to the network. Remember to use firewall if you are going to run this in an untrusted network or on a machine that has public IP address. You can also use the following command to publish the port to only localhost, which is the same behavior as the official bridge package.

```
docker run -d --name=protonmail-bridge -v protonmail:/root -p 127.0.0.1:1025:25/tcp -p 127.0.0.1:1143:143/tcp --restart=unless-stopped shenxn/protonmail-bridge
```

Besides, you can publish only port 25 (SMTP) if you don't need to receive any email (e.g. as a email notification service).

## Bridge CLI Guide

The initialization step exposes the bridge CLI so you can do things like switch between combined and split mode, change proxy, etc. The [official guide](https://protonmail.com/support/knowledge-base/bridge-cli-guide/) gives more information on to use the CLI.
