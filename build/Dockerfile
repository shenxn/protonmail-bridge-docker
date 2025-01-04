FROM golang:1.23 AS build

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends git build-essential libsecret-1-dev

# Build
WORKDIR /build/
COPY build.sh VERSION /build/
RUN bash build.sh

FROM debian:bookworm
LABEL maintainer="Ryan Deushane <radeushane@gmail.com>"

EXPOSE 25/tcp 143/tcp

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass procps libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Install protonmail
COPY --from=build /build/proton-bridge/bridge /protonmail/
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
