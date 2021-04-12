#!/usr/bin/env bash

./cluster-variables.sh

kubectl --kubeconfig $WEST -n argocd apply gloo-edge/gloo-edge.yaml