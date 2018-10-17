#!/bin/bash

DOCKER_IMAGE=monsoon/ldap:0.0.1
echo "Building Docker image: $DOCKER_IMAGE"
docker build --no-cache -t $DOCKER_IMAGE .
