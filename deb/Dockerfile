FROM ubuntu:jammy
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

# These are only exported if running as root
EXPOSE 25/tcp
EXPOSE 143/tcp

EXPOSE 2025/tcp
EXPOSE 2143/tcp

WORKDIR /protonmail

# Copy bash scripts
COPY gpgparams install.sh entrypoint.sh VERSION /protonmail/

# Install dependencies and protonmail bridge
RUN bash install.sh

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
