FROM debian:sid-slim
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

# These are only exported if running as root
EXPOSE 25/tcp
EXPOSE 143/tcp

EXPOSE 2025/tcp
EXPOSE 2143/tcp

WORKDIR /protonmail

# Copy bash scripts
COPY gpgparams install.sh entrypoint.sh VERSION /protonmail/

RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass procps libsecret-1-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy bash scripts
COPY gpgparams entrypoint.sh /protonmail/

# Install dependencies and protonmail bridge
RUN bash install.sh

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
