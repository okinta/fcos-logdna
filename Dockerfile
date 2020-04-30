ARG UBUNTU_VERSION=18.04
FROM ubuntu:$UBUNTU_VERSION

# Install tools to install other tools
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        unzip \
        wget

# Grab wait-for-it script so we know when Vault is ready
RUN wget -q -O wait-for-it.zip \
        https://s3.okinta.ge/wait-for-it-c096cface5fbd9f2d6b037391dfecae6fde1362e.zip \
    && unzip wait-for-it.zip \
    && rm -f wait-for-it.zip \
    && mkdir -p /deps/usr/local/bin \
    && mv wait-for-it-master/wait-for-it.sh /deps/usr/local/bin/wait-for-it \
    && chmod o+x /deps/usr/local/bin/wait-for-it

# Install gettext for envsubst
RUN apt-get install --no-install-recommends -y gettext-base \
    && mkdir -p /deps/usr/bin \
    && cp /usr/bin/envsubst /deps/usr/bin \
    && chmod o+x /deps/usr/bin/envsubst

# Download logdna-agent
RUN mkdir -p /deps/usr/local/bin \
    && wget -q -O /deps/usr/local/bin/logdna-agent \
        https://s3.okinta.ge/logdna-agent-b793918006f255887d4c6a67224f5c1e84a68615 \
    && chmod o+x /deps/usr/local/bin/logdna-agent

COPY files /deps
RUN chmod a+x /deps/bin/entrypoint.sh

FROM ubuntu:$UBUNTU_VERSION

# Install systemd so we can read logs via journalctl
RUN apt-get update \
    && apt-get install -y --no-install-recommends systemd \
    && rm -rf /var/lib/apt/lists/*

# Pull in what we need from the builder container
COPY --from=0 /deps /

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["agent"]
