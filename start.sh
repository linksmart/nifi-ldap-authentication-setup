#!/bin/bash

if [ ! -f ./nifi/secrets/keystore.jks -o ! -f ./nifi/secrets/truststore.jks ]; then
    echo "[ERROR] keystore.jks or truststore.jks is missing in ./nifi/secrets"
    echo "Launching aborted"
    exit 1
fi

if [ ! -f ./.env ]; then
    echo "[ERROR] .env file is missing. Please run ./scripts/setup.sh first"
    echo "Launching aborted"
    exit 1
fi

docker-compose up