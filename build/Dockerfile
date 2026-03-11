# Trixie (Debian 13) supports golang on all target platforms including riscv64.
FROM debian:trixie-slim AS build

ARG version

# Install dependencies
RUN apt-get update && apt-get install -y golang build-essential libsecret-1-dev libfido2-dev libcbor-dev

# Build
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/
RUN make build-nogui vault-editor

FROM debian:trixie-slim
LABEL maintainer="Trent Maetzold <trent@trkm.io>"
LABEL org.opencontainers.image.source="https://github.com/trent-maetzold/protonmail-bridge-docker"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass libsecret-1-0 libfido2-1 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Copy protonmail
COPY --from=build /build/bridge /protonmail/
COPY --from=build /build/proton-bridge /protonmail/
COPY --from=build /build/vault-editor /protonmail/

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
