# ProtonMail IMAP/SMTP Bridge Docker Container

> Fork of [shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker) with build fixes, updated dependencies, and GHCR publishing.

![build badge](https://github.com/trent-maetzold/protonmail-bridge-docker/workflows/build%20from%20source/badge.svg)

This is an unofficial Docker container of the [ProtonMail Bridge](https://protonmail.com/bridge/).

GHCR: `ghcr.io/trent-maetzold/protonmail-bridge`

## Changes from upstream

- Fixed build for proton-bridge v3.22+ (added `libfido2` dependency)
- Switched base image from `debian:sid` to `debian:trixie` (stable)
- Removed DockerHub publishing (GHCR only)
- Removed Gitee mirror workflow
- Merged version check into build workflow with scheduled auto-update
- Updated all GitHub Actions to current versions
- Replaced deprecated Anchore scan with Trivy
- Default docker-compose binds to localhost only (security)
- Updated maintainer labels and security policy

## ARM Support

ARM devices (`arm64` and `arm/v7`) are supported. Use the images tagged with `build`.

## Tags

There are two types of images:
- `deb`: Images based on the official [.deb release](https://protonmail.com/bridge/install). `amd64` only.
- `build`: Images compiled from [source code](https://github.com/ProtonMail/proton-bridge). Supports `amd64`, `arm64`, `arm/v7`, and `riscv64`.

| tag | description |
| -- | -- |
| `latest` | latest `build` image |
| `build` | latest `build` image |
| `[version]-build` | `build` images |

## Initialization

To initialize and add an account to the bridge:

```
docker run --rm -it -v protonmail:/root ghcr.io/trent-maetzold/protonmail-bridge:build init
```

Or with Docker Compose:

```
docker compose run protonmail-bridge init
```

Wait for the bridge to start, use `login` to add your account, `info` to see credentials, then `exit`. You may need `CTRL+C` to fully exit.

## Run

```
docker run -d --name=protonmail-bridge -v protonmail:/root \
  -p 127.0.0.1:1025:25/tcp -p 127.0.0.1:1143:143/tcp \
  --restart=unless-stopped ghcr.io/trent-maetzold/protonmail-bridge:build
```

Or with Docker Compose:

```
docker compose up -d
```

## Security

The default configuration binds ports to localhost only. If you need network access, update the port bindings — but use a firewall on untrusted networks.

## Bridge CLI Guide

The initialization step exposes the bridge CLI for configuration (combined/split mode, proxy, etc.). See the [official guide](https://protonmail.com/support/knowledge-base/bridge-cli-guide/).

## Build

To build locally:

```
cd build
docker build --build-arg version=v3.22.0 .
```

## Acknowledgments

This project is a fork of [shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker) by [Xiaonan Shen](https://github.com/shenxn), which provided the original Dockerfiles, entrypoint scripts, and CI pipeline. Some scripts are based on [Hendrik Meyer's work](https://gitlab.com/T4cC0re/protonmail-bridge-docker).

## License

[GPLv3](LICENSE)
