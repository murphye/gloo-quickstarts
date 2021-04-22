#!/usr/bin/env bash

kubectl --context cluster-central create namespace argocd
#kubectl --context cluster-central apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --context cluster-central apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/applicationset/v0.1.0/manifests/install-with-argo-cd.yaml

# TODO: Can expose via external LB?
kubectl --context cluster-central patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Disable Authentication?
# kubectl --kubeconfig $CENTRAL patch deploy argocd-server -n argocd -p '[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--disable-auth"}]' --type json --context cluster-central

###########################################################
# Change all admin password to be "admin"

kubectl -n argocd patch secret argocd-secret --context cluster-central \
  -p '{"stringData": { 
    "admin.password": "$2a$10$ldvEUwliowstaKXsWbK5b.mvN79pN8yFqQzq1Vq50fIEnzHGhljCa", 
    "admin.passwordMtime": "'$(date +%FT%T%Z)'" 
  }}'

###########################################################

echo "\n###########################################################"
echo "You can log into Argo with \"admin/admin\"\n"

echo "Access CENTRAL Argo CD instance:"
echo "kubectl --context cluster-central port-forward svc/argocd-server -n argocd --address 0.0.0.0 11180:443"

echo "Check status of Argo CD pods:"
echo "kubectl --context cluster-central -n argocd get pods"