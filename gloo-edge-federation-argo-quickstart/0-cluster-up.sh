#!/usr/bin/env bash
docker-compose -p gloo-edge-federation-argo-quickstart up -d --build

chmod 775 *.sh