### The Deb install is just a repack of the official ProtonMail Bridge deb package with less dependencies.
### I recommend you don't use this. It's here for legacy reasons.

FROM golang:1.26-trixie AS build

ARG version
ENV version=${version}


RUN apt-get update && apt-get install -y build-essential libsecret-1-dev libfido2-dev libcbor-dev

# Build
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/
RUN make build-nogui vault-editor

# -----------------------------------------------------------------------------

FROM debian:trixie-slim
LABEL maintainer="Simon Felding <sife@adm.ku.dk>"

# Select PTY tool for manage/attach commands: dtach (default), abduco, reptyr
ARG PTY_TOOL=dtach
ENV PTY_TOOL=${PTY_TOOL}

EXPOSE 25/tcp
EXPOSE 143/tcp

WORKDIR /protonmail

COPY gpgparams entrypoint.sh /protonmail/
# Copy protonmail
COPY --from=build /build/bridge /protonmail/
COPY --from=build /build/proton-bridge /protonmail/
COPY --from=build /build/vault-editor /protonmail/

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         socat pass libsecret-1-0 libfido2-1 ca-certificates procps \
    && case "${PTY_TOOL}" in \
         dtach)  apt-get install -y --no-install-recommends dtach  ;; \
         abduco) apt-get install -y --no-install-recommends abduco ;; \
         reptyr) apt-get install -y --no-install-recommends reptyr ;; \
         *) echo "Unsupported PTY_TOOL: ${PTY_TOOL}. Supported values are: dtach, abduco, reptyr." >&2; exit 1 ;; \
       esac \
    && chmod +x /protonmail/entrypoint.sh \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=120s \
  CMD /bin/bash -c "true < /dev/tcp/localhost/25"

ENTRYPOINT ["/protonmail/entrypoint.sh"]
CMD ["run"]
