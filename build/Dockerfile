FROM debian:sid-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y git golang build-essential libsecret-1-dev

# Build
WORKDIR /build/
COPY build.sh VERSION /build/
RUN bash build.sh

FROM debian:sid-slim
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

# These are only exported if running as root
EXPOSE 25/tcp
EXPOSE 143/tcp

EXPOSE 2025/tcp
EXPOSE 2143/tcp

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Copy protonmail
COPY --from=build /build/proton-bridge/bridge /protonmail/
COPY --from=build /build/proton-bridge/proton-bridge /protonmail/

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
