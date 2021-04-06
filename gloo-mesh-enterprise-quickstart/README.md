# Gloo Mesh Enterprise Quickstart

## About this Quickstart

This Quickstart is intended to show the very basics of installing Mesh Enterprise and ...

## Tested With

* k3d 4.4.0
* MetalLB 0.9.6
* Istio 1.9
* Helm 3.5.3
* Gloo Mesh 1.0.0

## Prerequisites

These setup commmands use Homebrew, and work on Mac, Linux, and Windows Subsystem for Linux (WSL).

### Clone Project

```bash
git clone https://github.com/murphye/gloo-quickstarts.git
cd gloo-quickstarts/gloo-edge-minimal-quickstart
```

### Install Homebrew
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Command Line Tools (as needed)

Run `brew upgrade` if already installed but running an older version.

```bash
brew install kubernetes-cli
brew install istioctl
brew install k3d
brew install helm
curl -sL https://run.solo.io/meshctl/install | sh
```

## Local Kubernetes Cluster

**Docker is required to run the examples.**

### Start k3d Cluster

This Kubernetes Cluster uses [k3d](http://k3d.io) and [MetalLB](https://metallb.universe.tf/) for a small, stateful development environment that is tuned for this particular Quickstart.

Management Cluster:
```bash
bash cluster-up.sh gloo-mesh-mgmt-cluster 6555
```

Remote Cluster:
```bash
bash cluster-up.sh gloo-mesh-remote-cluster 6556
```

It will take a brief moment for MetalLB to install and run on each cluster. You can check with `kubectl --context k3d-gloo-mesh-mgmt-cluster get pods -n metallb-system` to make sure the pods are running.

You can change the context with `kubectl config use-context k3d-gloo-mesh-mgmt-cluster` or `kubectl config use-context k3d-gloo-mesh-remote-cluster`.

## Install Istio

Istio needs to be installed on each k3d cluster.

`kubectl config use-context k3d-gloo-mesh-mgmt-cluster`

```
istioctl operator init

kubectl create ns istio-system

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
```

`kubectl config use-context k3d-gloo-mesh-remote-cluster`

```
istioctl operator init

kubectl create ns istio-system

kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
```

## Setup Istio Ingress on Management Cluster

`kubectl config use-context k3d-gloo-mesh-mgmt-cluster`

Create the `Gateway`.

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: gloo-mesh-ingress
  namespace: gloo-mesh
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: PASSTHROUGH
      hosts:
        - "enterprise-networking.gloo-mesh"
EOF
```

Create the `VirtualService`.

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gloo-mesh-ingress
  namespace: gloo-mesh
spec:
  hosts:
    - "enterprise-networking.gloo-mesh"
  gateways:
    - gloo-mesh/gloo-mesh-ingress
  tls:
    - match:
        - port: 443
          sniHosts:
          - enterprise-networking.gloo-mesh
      route:
        - destination:
            host: enterprise-networking.gloo-mesh.svc.cluster.local
            port:
              number: 9900
EOF
```

Add to `/etc/hosts` this entry `127.0.0.1   enterprise-networking.gloo-mesh`.

## Install Gloo Mesh with Helm

```
kubectl config use-context k3d-gloo-mesh-mgmt-cluster

helm repo add gloo-mesh-enterprise https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise
```

(Optional) View Helm values.
```
helm show values gloo-mesh-enterprise/gloo-mesh-enterprise
```

```
kubectl create ns gloo-mesh

helm install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise --namespace gloo-mesh \
  --set enterprise-networking.enterpriseNetworking.serviceType=LoadBalancer --set licenseKey=YOUR_GLOO_MESH_ENTERPRISE_LICENSE_KEY
```

Now, verify the install:

```
kubectl get pods -n gloo-mesh
```
and run:

```
meshctl check
```

## Register Cluster with Helm

```
CLUSTER_NAME=remote-cluster
REMOTE_CONTEXT=k3d-remote-cluster

kubectl create ns gloo-mesh --context $REMOTE_CONTEXT
```

### Copy the Root Certificate from the Management Cluster to the Remote Cluster

* TODO: Want to generate this CA certificate externally rather than pull out of the cluster itself *

Now we will get the value of the root CA certificate and create a secret in the remote cluster:

```
MGMT_CONTEXT=k3d-mgmt-cluster

kubectl get secret relay-root-tls-secret -n gloo-mesh --context $MGMT_CONTEXT -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context $REMOTE_CONTEXT --from-file ca.crt=ca.crt

rm ca.crt
```

### Copy the Bootstrap Token from the Management Cluster to the Remote Cluster

* TODO: Wantt to generate this Token in advance and pass it to the Gloo Mesh install *

```
kubectl get secret relay-identity-token-secret -n gloo-mesh --context $MGMT_CONTEXT -o jsonpath='{.data.token}' | base64 -d > token

kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context $REMOTE_CONTEXT --from-file token=token

rm token
```

### Install the Enterprise Agent

Set variables:

```
CLUSTER_NAME=remote-cluster
REMOTE_CONTEXT=k3d-remote-cluster
ENTERPRISE_NETWORKING_VERSION=1.0.0
```

Deploy the Relay Agent:

```
helm install enterprise-agent enterprise-agent/enterprise-agent \
  --namespace gloo-mesh \
  --set relay.serverAddress=enterprise-networking.gloo-mesh:43 \
  --set relay.authority=enterprise-networking.gloo-mesh \
  --set relay.cluster=${CLUSTER_NAME} \
  --kube-context=${REMOTE_CONTEXT} \
  --version ${ENTERPRISE_NETWORKING_VERSION}
```

## Next Steps

Please see the [Gloo Edge Quickstart Guide](https://docs.solo.io/gloo-edge/latest/guides/traffic_management/hello_world/) for more information about this exercise.

## Wrapping Up

### Stop k3d Cluster

This will retain the cluster state, rather than destroy it.

```bash
k3d cluster stop gloo-edge-minimal
```

### Restart k3d Cluster

This will restart the cluster to its previous state.

```bash
k3d cluster start gloo-edge-minimal
```

### Delete k3d Cluster

This will permanently delete the cluster.

```bash
k3d cluster delete gloo-edge-minimal
```

## References

* https://k3d.io
* https://metallb.universe.tf
* https://docs.solo.io/gloo-edge/latest/getting_started