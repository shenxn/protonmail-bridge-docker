# syntax=docker/dockerfile:1
### The Deb install is just a repack of the official ProtonMail Bridge deb package with less dependencies.
### I recommend you don't use this. It's here for legacy reasons.

# =============================================================================
# BUILD STAGE
# =============================================================================
FROM golang:1.26-trixie AS build

ARG version
ENV version=${version}

# ---------------------------------------------------------------------------
# LTO — why ENV CGO_LDFLAGS didn't work:
#
#   The Makefile's go-build-finalize on Linux expands to:
#       CGO_LDFLAGS="${LIBFIDO2_LDFLAGS}" go build ...
#   That inline shell assignment *overwrites* any CGO_LDFLAGS inherited from
#   the Docker environment entirely.
#
#   Fix: pass LIBFIDO2_LDFLAGS on the make command line (see RUN step below).
#   make CLI variables override Makefile ?= and := definitions, so our flags
#   reach the CGO_LDFLAGS inline assignment verbatim.
#
#   To disable LTO at build time:
#       docker buildx build --build-arg CGO_LTO_FLAGS="" ...
# ---------------------------------------------------------------------------
ARG CGO_LTO_FLAGS="-flto=auto -O2"

# -trimpath: the Makefile never sets this flag, so GOFLAGS is safe here.
# Strips host machine paths from the binary → reproducible builds, no path leaks.
ENV GOFLAGS="-trimpath"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
         build-essential \
         libsecret-1-dev \
         libfido2-dev \
         libcbor-dev

# ---------------------------------------------------------------------------
# Fetch source via BuildKit's git ADD (shallow clone at the requested ref).
# Because the entire tree arrives in one shot we cannot pre-copy go.mod,
# but the module cache mount below still avoids re-downloading dependencies.
# ---------------------------------------------------------------------------
ADD https://github.com/ProtonMail/proton-bridge.git#${version} /build/
WORKDIR /build/

# ---------------------------------------------------------------------------
# Pre-seed the Go module cache.
# This layer is invalidated only when go.mod / go.sum change (dep upgrades).
# On pure source changes the cache is warm and this step is near-instant.
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked \
    go mod download -x

# ---------------------------------------------------------------------------
# Compile.
#
# Cache mounts:
#   /go/pkg/mod          — downloaded module zips (read, shared)
#   /root/.cache/go-build — incremental .a object cache (read-write, locked)
#
# make variable overrides:
#   LIBFIDO2_LDFLAGS — appends LTO flags to the CGO_LDFLAGS inline assignment
#                      in go-build-finalize without touching any other flags.
#                      Default Makefile value: -lfido2 -lcbor -lssl -lcrypto
#
# Why not -s -w here:
#   The Makefile builds its own -ldflags chain:
#       BUILD_FLAGS += -ldflags '${GO_LDFLAGS}'
#   GO_LDFLAGS carries the -X version/revision constants computed at build
#   time. Overriding GO_LDFLAGS on the CLI loses those constants.
#   GOFLAGS=-ldflags="-s -w" is silently ignored when the Makefile already
#   passes -ldflags on the go build command line (last -ldflags wins in go).
#   → We strip the binaries in the next step instead.
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    make build-nogui vault-editor \
        BUILD_ENV=prod \
        LIBFIDO2_LDFLAGS="-lfido2 -lcbor -lssl -lcrypto ${CGO_LTO_FLAGS}"

# ---------------------------------------------------------------------------
# Strip debug symbols — equivalent to go -ldflags="-s -w".
# Typically saves 25-35 % on binary size.
# Remove this RUN if you need delve / runtime stack traces.
# ---------------------------------------------------------------------------
RUN strip --strip-all \
        /build/proton-bridge \
        /build/bridge \
        /build/vault-editor

# =============================================================================
# RUNTIME STAGE — minimal Debian image, no build toolchain
# =============================================================================
FROM debian:trixie-slim
LABEL maintainer="Simon Felding <sife@adm.ku.dk>"

# Select PTY tool for manage/attach commands: dtach (default), abduco, reptyr
ARG PTY_TOOL=dtach
ENV PTY_TOOL=${PTY_TOOL}

EXPOSE 25/tcp
EXPOSE 143/tcp

WORKDIR /protonmail

COPY gpgparams entrypoint.sh healthcheck.sh /protonmail/

COPY --from=build /build/bridge        /protonmail/
COPY --from=build /build/proton-bridge /protonmail/
COPY --from=build /build/vault-editor  /protonmail/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
         socat pass libsecret-1-0 libfido2-1 ca-certificates procps \
    && case "${PTY_TOOL}" in \
         dtach)  apt-get install -y --no-install-recommends dtach  ;; \
         abduco) apt-get install -y --no-install-recommends abduco ;; \
         reptyr) apt-get install -y --no-install-recommends reptyr ;; \
         *) echo "Unsupported PTY_TOOL: ${PTY_TOOL}. Supported: dtach, abduco, reptyr." >&2 ; exit 1 ;; \
       esac \
    && chmod +x /protonmail/entrypoint.sh /protonmail/healthcheck.sh \
    && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=120s \
  CMD /protonmail/healthcheck.sh

ENTRYPOINT ["/protonmail/entrypoint.sh"]
CMD ["run"]
