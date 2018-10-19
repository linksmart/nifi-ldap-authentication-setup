#!/bin/bash

if [ ! -f ./nifi/secrets/keystore.jks -o ! -f ./nifi/secrets/truststore.jks ]; then
    echo "[ERROR] keystore.jks or truststore.jks is missing in ./nifi/secrets"
    echo "Launching aborted"
    exit 1
fi

# Run the setup script
./scripts/setup.sh

docker-compose up