#!/usr/bin/env bash
docker-compose -p gloo-edge-federation-argo-quickstart up -d 

chmod 775 *.sh
./cluster-variables.sh