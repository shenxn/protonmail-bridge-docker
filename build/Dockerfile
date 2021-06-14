FROM golang:1.16 AS build

# Install dependencies
RUN apt-get update && apt-get install -y libsecret-1-dev

# Build
WORKDIR /build/
COPY build.sh VERSION /build/
RUN bash build.sh

FROM ubuntu:bionic
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        expect socat pass libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy protonmail
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

# Copy bash scripts
COPY gpgparams entrypoint.sh login.exp /protonmail/

RUN chmod +x /protonmail/login.exp

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
