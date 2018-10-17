#!/bin/bash

MAVEN_IMAGE=maven:3.5.3-jdk-8-alpine

echo "Building processors NAR file"
#mvn -f src/pom.xml clean package -DskipTests
docker run -it --rm -v $PWD/src:/usr/src/app -w /usr/src/app $MAVEN_IMAGE mvn clean package -DskipTests

if [ ! -f ./secrets/keystore.jks ]; then
    echo "Generating self signed certificate"
    docker run -it --rm -v "$PWD/secrets":/usr/src/secrets -w /usr/src/secrets $MAVEN_IMAGE /usr/src/secrets/generate-certificates.sh
fi 

DOCKER_IMAGE=monsoon/nifi:0.0.1
echo "Building Docker image: $DOCKER_IMAGE"
docker build --force-rm --no-cache=true -t $DOCKER_IMAGE .
