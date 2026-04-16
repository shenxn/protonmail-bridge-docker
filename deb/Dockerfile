### The Deb install is just a repack of the official ProtonMail Bridge deb package with less dependencies.
### I recommend you don't use this. It's here for legacy reasons.

FROM debian:sid-slim AS build

COPY install.sh PACKAGE /
RUN apt-get update && apt-get install -y wget binutils

# Repack deb (removes unnecessary dependencies and produces /protonmail.deb)
RUN bash /install.sh

FROM debian:sid-slim
LABEL maintainer="Simon Felding <sife@adm.ku.dk>"

# Select PTY tool for manage/attach commands: dtach (default), abduco, reptyr
ARG PTY_TOOL=dtach
ENV PTY_TOOL=${PTY_TOOL}

EXPOSE 25/tcp
EXPOSE 143/tcp

WORKDIR /protonmail

# Copy bash scripts
COPY gpgparams entrypoint.sh PACKAGE /protonmail/
COPY --from=build /protonmail.deb /tmp/protonmail.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends /tmp/protonmail.deb socat pass libsecret-1-0 libfido2-1 ca-certificates procps \
    && case "${PTY_TOOL}" in \
         dtach)  apt-get install -y --no-install-recommends dtach  ;; \
         abduco) apt-get install -y --no-install-recommends abduco ;; \
         reptyr) apt-get install -y --no-install-recommends reptyr ;; \
         *) echo "Unsupported PTY_TOOL: ${PTY_TOOL}. Supported values are: dtach, abduco, reptyr." >&2; exit 1 ;; \
       esac \
    && chmod +x /protonmail/entrypoint.sh \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=120s \
  CMD /bin/bash -c "true < /dev/tcp/localhost/25 && true < /dev/tcp/localhost/143 && true < /dev/tcp/localhost/1025 && true < /dev/tcp/localhost/1143"

ENTRYPOINT ["/protonmail/entrypoint.sh"]
CMD ["run"]
