### The Deb install is just a repack of the official ProtonMail Bridge deb package with less dependencies.
### I recommend you don't use this. It's here for legacy reasons.

FROM debian:trixie-slim AS build

COPY install.sh PACKAGE /
RUN apt-get update && apt-get install -y wget binutils

# Repack deb (removes unnecessary dependencies and produces /protonmail.deb)
RUN bash /install.sh

FROM debian:trixie-slim
LABEL maintainer="Trent Maetzold <trent@trkm.io>"
LABEL org.opencontainers.image.source="https://github.com/trent-maetzold/protonmail-bridge-docker"

EXPOSE 25/tcp
EXPOSE 143/tcp

WORKDIR /protonmail

# Copy bash scripts
COPY gpgparams entrypoint.sh PACKAGE /protonmail/
COPY --from=build /protonmail.deb /tmp/protonmail.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends /tmp/protonmail.deb socat pass libsecret-1-0 ca-certificates procps \
    && rm -rf /var/lib/apt/lists/*

CMD ["bash", "/protonmail/entrypoint.sh"]
