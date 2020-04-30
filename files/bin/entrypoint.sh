#!/usr/bin/env bash

# Wait for Vault to be ready so we can pull config from it
wait-for-it vault.in.okinta.ge:7020

# Grab LogDNA's ingestion key so we can forward logs
INGESTION_KEY=$(timeout 5s wget -q -O - http://vault.in.okinta.ge:7020/api/kv/logdna_ingestion_key)
export INGESTION_KEY
if [ -z "$INGESTION_KEY" ]; then
    echo "Could not obtain LogDNA ingestion key from Vault" >&2
    exit 1
fi

HOSTNAME=$(hostname)
export HOSTNAME

envsubst < /etc/logdna.conf.template > /etc/logdna.conf

export USEJOURNALD=files

if [ "$1" = "agent" ]; then
    exec logdna-agent start

else
    exec "$@"
fi
