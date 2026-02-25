# ProtonMail Bridge Docker Container

![build badge](https://github.com/dancwilliams/protonmail-bridge-docker/workflows/build%20from%20source/badge.svg)
![version badge](https://img.shields.io/docker/v/dancwilliams/protonmail-bridge)
![image size badge](https://img.shields.io/docker/image-size/dancwilliams/protonmail-bridge/latest)
![docker pulls badge](https://img.shields.io/docker/pulls/dancwilliams/protonmail-bridge)

An unofficial Docker container for the [Proton Mail Bridge](https://proton.me/mail/bridge), maintained by the community. This is a fork of [shenxn/protonmail-bridge-docker](https://github.com/shenxn/protonmail-bridge-docker), kept up to date and actively maintained.

- **Docker Hub:** [dancwilliams/protonmail-bridge](https://hub.docker.com/r/dancwilliams/protonmail-bridge)
- **GitHub:** [dancwilliams/protonmail-bridge-docker](https://github.com/dancwilliams/protonmail-bridge-docker)
- **GHCR:** `ghcr.io/dancwilliams/protonmail-bridge-docker`

## What's different from upstream

This fork includes fixes and improvements that are not yet merged upstream:

- **Fixes v3.22.0+** — adds missing `libfido2` and `libcbor` runtime dependencies that caused containers to fail to start
- **Auto-updater disabled** — the bridge's built-in self-updater is blocked; version management is handled by the container image itself (no more broken arm64 containers due to amd64 binary replacement)
- **Long-uptime stability fix** — replaced the fragile stdin pipe with `sleep infinity`, preventing the bridge from detaching after several days of uptime
- **Stale GPG socket cleanup** — removes leftover `S.gpg-agent` sockets on startup, preventing auth failures after container restarts
- **Health check** — Docker reports container health based on the bridge process status
- **Automated version tracking** — new Proton Bridge releases are detected within 24 hours and trigger a new multi-arch image build automatically

## Migrating to this image

For most users, upgrading is:

```
docker compose pull && docker compose up -d
```

or `docker pull dancwilliams/protonmail-bridge` + container restart. No re-initialization is required.

### Breaking changes

**arm/v7 removed (v3.22.0+)**
32-bit ARM is no longer supported. The upstream `go-libfido2` dependency is incompatible with 32-bit ARM and there is no fix available upstream. Users on arm/v7 hardware should stay on an older image tag or switch to a supported platform.

**Tag format changed**
Tags no longer carry a `-build` suffix. If you were pinning to a tag like `v3.21.2-build`, update your compose file or run command to use `v3.21.2` instead. Users tracking `latest` are unaffected.

**Auto-updater disabled**
The bridge's built-in self-updater is now permanently blocked (bridge binaries are made read-only at image build time). This prevents the updater from replacing container binaries at runtime, which previously caused broken arm64 containers when it downloaded an amd64 binary. Version updates now come exclusively through new container image releases, which this repository handles automatically via a daily version check.

## Architectures

Images are built for the following platforms from source:

| Architecture | Supported |
|---|---|
| `linux/amd64` | Yes |
| `linux/arm64/v8` | Yes |
| `linux/arm/v7` | No — upstream go-libfido2 dependency does not support 32-bit ARM as of v3.22.0 |
| `linux/riscv64` | Yes |

## Tags

| Tag | Description |
|---|---|
| `latest` | Most recent release |
| `v3.x.x` | Specific Proton Bridge version |

## Initialization

Before running the container for the first time, you must initialize it and log in to your Proton account.

**Using `docker run`:**
```
docker run --rm -it -v protonmail:/root dancwilliams/protonmail-bridge init
```

**Using Docker Compose:**
```
docker compose run protonmail-bridge init
```

Wait for the bridge to start, then you will see the [Proton Bridge interactive shell](https://proton.me/support/bridge-cli-guide). Use the `login` command and follow the prompts to add your account. Once logged in, run `info` to see the IMAP/SMTP credentials your mail client will need. Then run `exit` to quit. You may need `CTRL+C` to exit the container entirely.

The credentials shown by `info` are what you enter in your email client — not your Proton account password.

## Run

**Using `docker run`:**
```
docker run -d \
  --name=protonmail-bridge \
  -v protonmail:/root \
  -p 1025:25/tcp \
  -p 1143:143/tcp \
  --restart=unless-stopped \
  dancwilliams/protonmail-bridge
```

**Using Docker Compose:**
```
docker compose up -d
```

See the included [docker-compose.yml](docker-compose.yml) for a working example.

## Security

Running the commands above exposes the bridge on all network interfaces. If you are on an untrusted network or a machine with a public IP, restrict the ports to localhost:

```
docker run -d \
  --name=protonmail-bridge \
  -v protonmail:/root \
  -p 127.0.0.1:1025:25/tcp \
  -p 127.0.0.1:1143:143/tcp \
  --restart=unless-stopped \
  dancwilliams/protonmail-bridge
```

If you only need outgoing email (e.g. for notifications), you can omit port `1143` (IMAP) entirely.

For security vulnerability reporting, see [SECURITY.md](SECURITY.md).

## Kubernetes

A [Helm chart](https://github.com/k8s-at-home/charts/tree/master/charts/stable/protonmail-bridge) is available for Kubernetes deployments. See the upstream issue [#23](https://github.com/shenxn/protonmail-bridge-docker/issues/23) for details.

For a non-Helm approach, see the guide in upstream issue [#6](https://github.com/shenxn/protonmail-bridge-docker/issues/6).

## Bridge CLI Guide

The `init` step drops you into the bridge CLI, which can also be used to switch between combined and split address mode, configure a proxy, and more. See the [official CLI guide](https://proton.me/support/bridge-cli-guide) for details.

## Building locally

To build the image yourself:

```
cd build
docker build --build-arg version=v3.22.0 -t protonmail-bridge .
```

Replace `v3.22.0` with the desired [Proton Bridge release tag](https://github.com/ProtonMail/proton-bridge/releases).

## Version updates

This repository checks for new Proton Bridge releases daily. When a new version is detected, the `VERSION` file is updated automatically and a new multi-arch image is built and pushed to Docker Hub and GHCR. No manual intervention is required.

## Credits

Originally created by [shenxn](https://github.com/shenxn). Scripts originally based on work by [Hendrik Meyer](https://gitlab.com/T4cC0re/protonmail-bridge-docker).
