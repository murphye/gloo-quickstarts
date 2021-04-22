#!/usr/bin/env bash
kubectl --context cluster-west -n argocd apply -f gloo-edge/gloo-edge.yaml