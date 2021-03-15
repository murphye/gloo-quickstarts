# Gloo Edge Minimal Quickstart

## About this Quickstart

This Quickstart is intended to show the very basics of installing Gloo Edge and running a simple Petstore application demo.

## Time to Complete

This exercise will take about **5 minutes**.

## Tested With

* k3d 4.3.0
* MetalLB 0.9.5
* Gloo Edge 1.6.15

## Prerequisites

These setup commmands use Homebrew, and work on Mac, Linux, and Windows Subsystem for Linux (WSL).

### Install Homebrew
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Command Line Tools (as needed)
```bash
brew install kubernetes-cli
brew install glooctl
brew install k3d
```

### Clone Project

```bash
git clone https://github.com/murphye/gloo-quickstarts.git
cd gloo-edge-minimal-quickstart
```

## Local Kubernetes Cluster

**Docker is required to run the examples.**

### Start k3d Cluster

This Kubernetes Cluster uses [k3d](http://k3d.io) and [MetalLB](https://metallb.universe.tf/) for a small, stateful development environment that is tuned for this particular Quickstart.

```bash
bash cluster-up.sh gloo-edge-minimal
```

It will take a brief moment for MetalLB to install and run. You can check with `kubectl get pods -n metallb-system` to make sure the pods are running.

## Install Gloo Edge via `glooctl`

`glooctl` is an easy way to install Gloo Edge for experimentation, but you can also use Helm. Please see the [Gloo Edge documentation](https://docs.solo.io/gloo-edge)_ for further information.

```bash
glooctl install gateway
```

It will take a brief moment for Gloo Edge to install and run. You can check with `kubectl get pods -n gloo-system` to make sure the pods are running.

## Excercise: Install the Petstore Sample Application

```bash
kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo/v1.2.9/example/petstore/petstore.yaml
```

### Create a Gloo Route

This will create a custom Route on the Gloo Edge Virtual Service that rewrites the path from `/api/pets` to `/all-pets`.

```bash
glooctl add route --path-exact /all-pets --dest-name default-petstore-8080 --prefix-rewrite /api/pets
```

There will initially be a "Pending" status for the Gloo Edge Virtual Service shown. You can view the status again, if you wish, with `glooctl get vs -n gloo-system`

#### `curl` the endpoint

```
curl http://localhost/all-pets
```

Expected result:

```json
[{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
```

If you receive `curl: (52) Empty reply from server`, it means that the Virtual Service is not yet ready, as MetalLB may still have been starting up. Please wait a moment and try again.

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