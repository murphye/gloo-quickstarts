# Gloo Edge OpenShift 3.11 Quickstart

## About this Quickstart

This Quickstart is intended to show the very basics of installing Gloo Edge onto OpenShift (OKD) 3.11 and running a simple Petstore application demo. While 3.11 is a legacy version of OpenShift, the installed base is significant.

## Time to Complete

This will take you **about 5 minutes**.

## Tested With

* OpenShift (OKD) 3.11.0 (Linux CLI)
* Gloo Edge 1.6.15
* Helm 3.5.2

## Prerequisites

These setup commmands use Homebrew, and work on Mac, Linux, and Windows Subsystem for Linux (WSL).

### Clone Project

```bash
git clone https://github.com/murphye/gloo-quickstarts.git
cd gloo-edge-openshift-3.11-quickstart
```

### Install Homebrew (as needed)
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Command Line Tools (as needed)

#### Install OpenShift CLI

This is the Linux CLI download link. Your best bet is to run this exercise in Linux, and a virtual machine would be OK.
```bash
wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz

tar -zvxf openshift-origin-client-tools-v3.11.0–0cbc58b-linux-64bit.tar.gz
```
Put `oc` on your executable path, or simply run with `./oc`.

#### Install Helm CLI

```
brew install helm
```

## Local OpenShift Cluster

**Docker is required to run the examples.**

### Start OpenShift Cluster

This example uses the `oc cluster up` mechanism to run OpenShift 3.11 locally, rather than use Minishift.

```bash
oc cluster up
```

### Log in as the OpenShift Administrator

```bash
export KUBECONFIG=openshift.local.clusterup/openshift-apiserver/admin.kubeconfig

oc login -u system:admin
```

## Install Gloo Edge via `helm`

It is advised to use Helm to install Gloo Edge on OpenShift.

```bash
oc new-project gloo-system
helm repo add gloo https://storage.googleapis.com/solo-public-helm

helm install gloo gloo/gloo --namespace gloo-system -f values.yaml
```

It will take a brief moment for Gloo Edge to install and run. You can check with `oc get pods -n gloo-system` to make sure the pods are running.

## Excercise: Install the Petstore Sample Application

```bash
oc apply -f https://raw.githubusercontent.com/solo-io/gloo/v1.2.9/example/petstore/petstore.yaml
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

## Next Steps

Please see the [Gloo Edge Quickstart Guide](https://docs.solo.io/gloo-edge/latest/guides/traffic_management/hello_world/) for more information about this exercise.

## Wrapping Up

### Stop OpenShift Cluster

This will retain the cluster state, rather than destroy it.

```bash
oc cluster down
```

### Restart k3d Cluster

This will restart the cluster to its previous state.

```bash
oc cluster up
```

## References

* https://docs.okd.io/3.11/cli_reference/get_started_cli.html#installing-the-cli
* https://docs.solo.io/gloo-edge/latest/getting_started
* https://docs.solo.io/gloo-edge/latest/installation/platform_configuration/cluster_setup/#openshift
* https://docs.solo.io/gloo-edge/latest/installation/platform_configuration/cluster_setup/#minishift