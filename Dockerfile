FROM debian:buster-slim
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp
ENV DEB_URL https://protonmail.com/download/protonmail-bridge_1.2.6-1_amd64.deb
WORKDIR /root

# Copy gpg parameters and .deb installer
COPY gpgparams /protonmail/

# Install dependencies and protonmail bridge
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat pass \
    && apt-get install -y wget \
    && wget -O /protonmail/protonmail.deb ${DEB_URL} \
    && apt-get install -y --no-install-recommends /protonmail/protonmail.deb \
    && apt-get purge -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm /protonmail/protonmail.deb

COPY entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
