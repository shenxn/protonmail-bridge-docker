FROM debian:buster-slim
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Copy bash scripts
COPY gpgparams install.sh entrypoint.sh releaserc /protonmail/

# Install dependencies and protonmail bridge
RUN bash /protonmail/install.sh

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
