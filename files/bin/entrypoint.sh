#!/usr/bin/env sh

# Wait for Vault to be ready so we can pull config from it
wait-for-it vault.in.okinta.ge:7020

# Grab LogDNA's ingestion key so we can forward logs
LOGDNA_INGESTION_KEY=$(wget -q -O - http://vault.in.okinta.ge:7020/api/kv/logdna_ingestion_key)
export LOGDNA_INGESTION_KEY
if [ -z "$LOGDNA_INGESTION_KEY" ]; then
    echo "Could not obtain LogDNA ingestion key from Vault" >&2
    exit 1
fi

envsubst < /fluentd/etc/fluent.conf.template > /fluentd/etc/fluent.conf

# The following is copied from:
# https://github.com/fluent/fluentd-docker-image/blob/db20ab074c179bc19002f42e493e21a568d39db5/v1.9/debian/entrypoint.sh

#source vars if file exists
DEFAULT=/etc/default/fluentd

if [ -r $DEFAULT ]; then
    set -o allexport
    . $DEFAULT
    set +o allexport
fi

# If the user has supplied only arguments append them to `fluentd` command
if [ "${1#-}" != "$1" ]; then
    set -- fluentd "$@"
fi

# If user does not supply config file or plugins, use the default
if [ "$1" = "fluentd" ]; then
    if ! echo $@ | grep ' \-c' ; then
       set -- "$@" -c /fluentd/etc/${FLUENTD_CONF}
    fi

    if ! echo $@ | grep ' \-p' ; then
       set -- "$@" -p /fluentd/plugins
    fi
fi

exec "$@"