FROM fluent/fluentd:v1.9-debian-1

USER root

# Install tools to install other tools
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        unzip \
        wget

# Install gettext for envsubst
RUN apt-get install --no-install-recommends -y gettext-base \
    && mkdir -p /deps/usr/bin \
    && cp /usr/bin/envsubst /deps/usr/bin

# Grab wait-for-it script so we know when Vault is ready
RUN wget -q -O wait-for-it.zip \
        https://s3.okinta.ge/wait-for-it-c096cface5fbd9f2d6b037391dfecae6fde1362e.zip \
    && unzip wait-for-it.zip \
    && rm -f wait-for-it.zip \
    && mkdir -p /deps/usr/local/bin \
    && mv wait-for-it-master/wait-for-it.sh /deps/usr/local/bin/wait-for-it \
    && chmod o+x /deps/usr/local/bin/wait-for-it

FROM fluent/fluentd:v1.9-debian-1

USER root

# Pull in what we need from the builder container
COPY --from=0 /deps /

RUN set -x \

    # Install build dependencies for fluentd plugins
    && buildDeps="sudo make gcc g++ libc-dev" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \

        # Install systemd dependency
        libsystemd0 \

        # Install wget so we can communicate with Vault
        ca-certificates wget \

    # Install fluentd plugins
    && gem install fluent-plugin-logdna -v 0.2.3 \
    && gem install fluent-plugin-systemd -v 1.0.1 \

    # Cleanup
    && SUDO_FORCE_REMOVE=yes \
        apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

COPY files /
RUN chmod a+x /bin/entrypoint.sh \
    && chown fluent:fluent /fluentd/etc/fluent.conf

RUN mkdir /fluentd/log/journal
