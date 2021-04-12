#!/usr/bin/env bash

./cluster-variables.sh

kubectl --kubeconfig $EAST create namespace argocd 
kubectl --kubeconfig $EAST apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --kubeconfig $EAST patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl --kubeconfig $CENTRAL create namespace argocd 
kubectl --kubeconfig $CENTRAL apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --kubeconfig $CENTRAL patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl --kubeconfig $WEST create namespace argocd
kubectl --kubeconfig $WEST apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl --kubeconfig $WEST patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

###########################################################
# Change all admin passwords to be "admin"

kubectl --kubeconfig $EAST -n argocd patch secret argocd-secret \
  -p '{"stringData": { 
    "admin.password": "$2a$10$ldvEUwliowstaKXsWbK5b.mvN79pN8yFqQzq1Vq50fIEnzHGhljCa", 
    "admin.passwordMtime": "'$(date +%FT%T%Z)'" 
  }}'

kubectl --kubeconfig $CENTRAL -n argocd patch secret argocd-secret \
  -p '{"stringData": { 
    "admin.password": "$2a$10$ldvEUwliowstaKXsWbK5b.mvN79pN8yFqQzq1Vq50fIEnzHGhljCa", 
    "admin.passwordMtime": "'$(date +%FT%T%Z)'" 
  }}'

kubectl --kubeconfig $WEST -n argocd patch secret argocd-secret \
  -p '{"stringData": { 
    "admin.password": "$2a$10$ldvEUwliowstaKXsWbK5b.mvN79pN8yFqQzq1Vq50fIEnzHGhljCa", 
    "admin.passwordMtime": "'$(date +%FT%T%Z)'" 
  }}'

###########################################################

echo "\n###########################################################"
echo "You can log into Argo with \"admin/admin\"\n"

echo "Access EAST Argo instance:"
echo "kubectl --kubeconfig \$EAST port-forward svc/argocd-server -n argocd --address 0.0.0.0 11080:443"

echo "Access CENTRAL Argo instance:"
echo "kubectl --kubeconfig \$CENTRAL port-forward svc/argocd-server -n argocd --address 0.0.0.0 11180:443"

echo "Access WEST Argo instance:"
echo "kubectl --kubeconfig \$WEST port-forward svc/argocd-server -n argocd --address 0.0.0.0 11280:443"

echo "Check status of Argo pods:"
echo "kubectl --kubeconfig \$EAST -n argocd get pods"
echo "kubectl --kubeconfig \$CENTRAL -n argocd get pods"
echo "kubectl --kubeconfig \$WEST -n argocd get pods"