#!/usr/bin/env bash

subnet=$(docker network inspect gloo-edge-federation-argo-quickstart_default | jq -r '.[0].IPAM.Config[0].Subnet')
ipParts=(${subnet//./ })
ipStart=${ipParts[0]}.${ipParts[1]}.${ipParts[2]}

metallbConfigMap1=`cat <<EOF
apiVersion: v1 
kind: ConfigMap 
metadata: 
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ipStart.246-$ipStart.255
EOF
`

metallbConfigMap2=`cat <<EOF
apiVersion: v1 
kind: ConfigMap 
metadata: 
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ipStart.236-$ipStart.245
EOF
`

metallbConfigMap3=`cat <<EOF
apiVersion: v1 
kind: ConfigMap 
metadata: 
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ipStart.226-$ipStart.235
EOF
`

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl --context cluster-east create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
echo "$metallbConfigMap1" | kubectl --context cluster-east apply -f -
kubectl --context cluster-east apply -f https://raw.githubusercontent.com/google/metallb/v0.9.6/manifests/metallb.yaml

kubectl --context cluster-central apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl --context cluster-central create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
echo "$metallbConfigMap2" | kubectl --context cluster-central apply -f -
kubectl --context cluster-central apply -f https://raw.githubusercontent.com/google/metallb/v0.9.6/manifests/metallb.yaml

kubectl --context cluster-west apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl --context cluster-west create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
echo "$metallbConfigMap3" | kubectl --context cluster-west apply -f -
kubectl --context cluster-west apply -f https://raw.githubusercontent.com/google/metallb/v0.9.6/manifests/metallb.yaml

echo "Check status of MetalLB pods:"
echo "kubectl --context cluster-east -n metallb-system get pods"
echo "kubectl --context cluster-central -n metallb-system get pods"
echo "kubectl --context cluster-west -n metallb-system get pods"
