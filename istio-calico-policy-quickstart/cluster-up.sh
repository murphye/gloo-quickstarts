#!/usr/bin/env bash

k3d_cluster_name=${1:-default}
k3d_cluster_port=${2:-6443}
k3d_server_count=${3:-2}

# k3d + Calico
k3d cluster create --servers $k3d_server_count --network k3d-$k3d_cluster_name --api-port $k3d_cluster_port -p "80:80@server[0]" -p "443:443@server[0]" -p "81:80@server[1]" -p "444:443@server[1]" --registry-create --no-lb --k3s-server-arg '--no-deploy=traefik' --k3s-server-arg '--flannel-backend=none' --volume "$(pwd)/calico-config.yaml:/var/lib/rancher/k3s/server/manifests/calico.yaml" $k3d_cluster_name

subnet=$(docker network inspect k3d-$k3d_cluster_name | jq -r '.[0].IPAM.Config[0].Subnet')
ipParts=(${subnet//./ })
ipStart=${ipParts[0]}.${ipParts[1]}.${ipParts[2]}

metallbConfigMap=`cat <<EOF
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

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
echo "$metallbConfigMap" | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.9.5/manifests/metallb.yaml