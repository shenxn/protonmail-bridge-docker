# The build image could be golang, but it currently does not support riscv64. Only debian:sid does, at the time of writing.
FROM debian:sid-slim AS build

ARG version

# Install dependencies
RUN apt-get update && apt-get install -y golang build-essential libsecret-1-dev libfido2-dev libcbor-dev

# Build
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/
RUN make build-nogui vault-editor

FROM debian:sid-slim
LABEL maintainer="Dan Williams <dancwilliams@github>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Monitor proton-bridge process health
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD bash -c "pgrep -f proton-bridge || exit 1"

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

# Prevent the bridge's built-in auto-updater from replacing the container binary at runtime.
# Version management is handled externally via the update-check workflow.
RUN chmod -w /protonmail/bridge /protonmail/proton-bridge /protonmail/vault-editor

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
