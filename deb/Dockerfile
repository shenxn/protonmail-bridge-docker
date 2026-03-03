### The Deb install is just a repack of the official ProtonMail Bridge deb package with less dependencies.
### I recommend you don't use this. It's here for legacy reasons.

FROM debian:sid-slim AS build

COPY install.sh PACKAGE /
RUN apt-get update && apt-get install -y wget binutils

# Repack deb (removes unnecessary dependencies and produces /protonmail.deb)
RUN bash /install.sh

# -----------------------------------------------------------------------------

FROM debian:sid-slim
LABEL maintainer="Simon Felding <sife@adm.ku.dk>"

# Select PTY tool for manage/attach commands: dtach (default), abduco, reptyr
ARG PTY_TOOL=dtach
ENV PTY_TOOL=${PTY_TOOL}

EXPOSE 25/tcp
EXPOSE 143/tcp

WORKDIR /protonmail

# PACKAGE is only needed in the build stage; don't copy it into the final image
COPY gpgparams entrypoint.sh /protonmail/
COPY --from=build /protonmail.deb /tmp/protonmail.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         /tmp/protonmail.deb \
         socat pass libsecret-1-0 libfido2-1 ca-certificates procps \
    && case "${PTY_TOOL}" in \
         dtach)  apt-get install -y --no-install-recommends dtach  ;; \
         abduco) apt-get install -y --no-install-recommends abduco ;; \
         reptyr) apt-get install -y --no-install-recommends reptyr ;; \
       esac \
    && chmod +x /protonmail/entrypoint.sh \
    && rm -rf /tmp/protonmail.deb /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=120s \
  CMD /bin/bash -c "true < /dev/tcp/localhost/25"

CMD ["/protonmail/entrypoint.sh", "run"]
