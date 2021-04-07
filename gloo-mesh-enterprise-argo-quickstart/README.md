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
cd gloo-quickstarts/gloo-mesh-enterprise-argo-quickstart
```

### Install Homebrew (If Needed)
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Command Line Tools (As Needed)

Run `brew upgrade` if already installed but running an older version.

```bash
brew install kubernetes-cli
brew install istioctl
brew install k3d
brew install argocd
brew install step
curl -sL https://run.solo.io/meshctl/install | sh
```

## Local Kubernetes Cluster

**Docker is required to run the examples.**

### Start k3d Cluster

This Kubernetes Cluster uses [k3d](http://k3d.io) and [MetalLB](https://metallb.universe.tf/) for a small, stateful development environment that is tuned for this particular Quickstart.

Management Cluster:
```bash
bash cluster-up-mgmt.sh gloo-mesh-mgmt-cluster 6555
```

Remote Cluster:
```bash
bash cluster-up-remote.sh gloo-mesh-remote-cluster 6556 81 444
```

 will take a brief moment for MetalLB to install and run on each cluster. You can check with `kubectl --context k3d-gloo-mesh-mgmt-cluster get pods -n metallb-system` to make sure the pods are running.

You can change the context with `kubectl config use-context k3d-gloo-mesh-mgmt-cluster` or `kubectl config use-context k3d-gloo-mesh-remote-cluster`.

## Install Argo

### Install Argo onto Management Cluster

```
kubectl config use-context k3d-gloo-mesh-mgmt-cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Install Argo onto Remote Cluster

```
kubectl config use-context k3d-gloo-mesh-remote-cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Get Argo password for Management Cluster

```
kubectl config use-context k3d-gloo-mesh-mgmt-cluster
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 9870:443
```

With a browser, login with admin/generated-password at https://localhost:9870.

### Get Argo password for Remote Cluster

```
kubectl config use-context k3d-gloo-mesh-remote-cluster
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
kubectl port-forward svc/argocd-server --address 0.0.0.0 -n argocd 9871:443
```

With a browser, login with admin/generated-password at https://localhost:9871.

## Install Istio

Istio needs to be installed on the remote cluster.

```
kubectl config use-context k3d-gloo-mesh-remote-cluster

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


## Supplemental Commands

These are the steps taken to generate the certificates and the Secrets packaged in this demo. These steps are not necessary, but may be helpful if you choose to adapt this demo.

### Generate Certificates

```
step ca init --name="host.k3d.internal" --dns="host.k3d.internal"
```

```
What IP and port will your new CA bind to?
✔ (e.g. :443 or 127.0.0.1:4343): :443█
What would you like to name the CA's first provisioner?
✔ (e.g. you@smallstep.com): eric.murphy@solo.io
✔ Password: _:^!9nN#pz&oiua#}_+g5MQ`jN{0d;`&

Generating root certificate... 
Generating intermediate certificate... 

✔ Root certificate: /home/eric/.step/certs/root_ca.crt
✔ Root private key: /home/eric/.step/secrets/root_ca_key
✔ Root fingerprint: 7184f1ece4e1deea2c056d1de0872d4e1dd3880b9f54b9c926139b1275dc32ca
✔ Intermediate certificate: /home/eric/.step/certs/intermediate_ca.crt
✔ Intermediate private key: /home/eric/.step/secrets/intermediate_ca_key
✔ Database folder: /home/eric/.step/db
✔ Default configuration: /home/eric/.step/config/defaults.json
✔ Certificate Authority configuration: /home/eric/.step/config/ca.json
```

```
step ca certificate --offline host.k3d.internal server.crt server.key 
```

### Generate Secrets

Management Root Certificate:
```
kubectl create secret generic relay-root-tls-secret -n gloo-mesh \
  --from-file=ca.crt=certs/relay-root.crt \
  --dry-run=client -oyaml > mgmt/gloo-mesh/relay-root-tls-secret.yaml
```

Remote Root Certificate:
```
kubectl create secret generic relay-root-tls-secret \
  --from-file=ca.crt=certs/relay-tls-signing.crt \
  --dry-run=client -oyaml > remote/gloo-mesh/relay-root-tls-secret.yaml
```

Management Signing Certificate:
```
kubectl create secret generic relay-tls-signing-secret \
  --from-file=tls.key=certs/relay-tls-signing.key \
  --from-file=tls.crt=certs/relay-tls-signing.crt \
  --from-file=ca.crt=certs/relay-root.crt \
  --dry-run=client -oyaml > mgmt/gloo-mesh/relay-tls-signing-secret.yaml
```

Management Server Certificate:
```
kubectl create secret generic relay-server-tls-secret \
  --from-file=tls.key=certs/relay-server-tls.key \
  --from-file=tls.crt=certs/relay-server-tls.crt \
  --from-file=ca.crt=certs/relay-root.crt \
  --dry-run=client -oyaml > mgmt/gloo-mesh/relay-server-tls-secret.yaml
```

Management Server Token:

kubectl create secret generic relay-identity-token-secret \
  --from-literal=token=2c0097c0-f789-4435-ab00-8c3ab33b5bc5 \
  --dry-run=client -oyaml > mgmt/gloo-mesh/relay-identity-token-secret.yaml

Remote Server Token:

kubectl create secret generic relay-identity-token-secret \
  --from-literal=token=2c0097c0-f789-4435-ab00-8c3ab33b5bc5 \
  --dry-run=client -oyaml > remote/gloo-mesh/relay-identity-token-secret.yaml

