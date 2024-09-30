FROM golang:1.23 AS build

# Install dependencies
# RUN apt-get update && apt-get install -y git build-essential libsecret-1-dev

RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install \
        libc6 \
        socat \
        pass \
        ca-certificates \
        wget \
        binutils \
        xz-utils \
        libsecret-1-dev \
        libgl1

# Build
WORKDIR /build/
COPY build.sh VERSION /build/
RUN --mount=type=cache,target=/root/.cache/go-build bash build.sh

FROM ubuntu:noble
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Copy protonmail
COPY --from=build /build/proton-bridge/bridge /protonmail/
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
