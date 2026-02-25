# debian:sid-slim is required for the build stage to support riscv64 (golang:bookworm does not).
# For the runtime stage we default to debian:bookworm-slim for stable, predictable package names.
# riscv64 requires debian:sid-slim at runtime too (bookworm has no riscv64 image);
# the workflow passes RUNTIME_IMAGE=debian:sid-slim for that platform.
FROM debian:sid-slim AS build

ARG version

# Install build dependencies
RUN apt-get update && apt-get install -y golang build-essential libsecret-1-dev libfido2-dev libcbor-dev

# Build
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/
RUN make build-nogui vault-editor

ARG RUNTIME_IMAGE=debian:bookworm-slim
FROM ${RUNTIME_IMAGE}
LABEL maintainer="Dan Williams <dancwilliams@github>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Monitor proton-bridge process health
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD bash -c "pgrep -f proton-bridge || exit 1"

# Install runtime dependencies
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
