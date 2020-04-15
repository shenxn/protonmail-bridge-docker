FROM debian:buster-slim AS setup

COPY setup.sh /bin/
RUN bash /bin/setup.sh


FROM debian:buster-slim
LABEL maintainer="Xiaonan Shen <s@sxn.dev>"

EXPOSE 25/tcp
EXPOSE 143/tcp

# Copy gpg parameters and .deb installer
COPY gpgparams install.sh entrypoint.sh /protonmail/
COPY --from=setup /protonmail/protonmail.deb /protonmail/

# Install dependencies and protonmail bridge
RUN bash /protonmail/install.sh

ENTRYPOINT ["bash", "/protonmail/entrypoint.sh"]
