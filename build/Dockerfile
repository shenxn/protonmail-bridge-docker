# ARG before any FROM is global and available in FROM instructions.
# debian:bookworm-slim is the default; the workflow overrides to debian:sid-slim for riscv64
# since bookworm has no riscv64 image.
ARG RUNTIME_IMAGE=debian:bookworm-slim@sha256:74d56e3931e0d5a1dd51f8c8a2466d21de84a271cd3b5a733b803aa91abf4421

# debian:sid-slim is required for the build stage to support riscv64 (golang:bookworm does not).
FROM debian:sid-slim@sha256:30128782ec2a5b0595723b21ee6be29adc2959a97fbff2b7cf5f582d28a5464b AS build

ARG version

# Install build dependencies
RUN apt-get -o Acquire::http::Timeout=30 update && apt-get -o Acquire::http::Timeout=30 install -y golang build-essential libsecret-1-dev libfido2-dev libcbor-dev

# Build
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/
RUN make build-nogui vault-editor

FROM ${RUNTIME_IMAGE}
LABEL maintainer="Dan Williams <dancwilliams@github>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Monitor proton-bridge process health
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD bash -c "pgrep -f proton-bridge || exit 1"

# Install runtime dependencies
RUN apt-get -o Acquire::http::Timeout=30 update \
    && apt-get -o Acquire::http::Timeout=30 install -y --no-install-recommends socat pass libsecret-1-0 libfido2-1 ca-certificates procps \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Copy protonmail
COPY --from=build /build/bridge /protonmail/
COPY --from=build /build/proton-bridge /protonmail/
COPY --from=build /build/vault-editor /protonmail/

# Prevent the bridge's built-in auto-updater from replacing the container binary at runtime.
# Version management is handled externally via the update-check workflow.
RUN chmod -w /protonmail/bridge /protonmail/proton-bridge /protonmail/vault-editor

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
