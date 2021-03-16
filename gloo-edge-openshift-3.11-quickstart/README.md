# Gloo Edge OpenShift 3.11 Quickstart (Work in Progress)

## About this Quickstart

This Quickstart is intended to show the very basics of installing Gloo Edge onto OpenShift (OKD) 3.11 and running a simple Petstore application demo. While 3.11 is a legacy version of OpenShift, the installed base is significant.

## Time to Complete

This will take you **about 15 minutes**.

## Tested With

* OpenShift (OKD) 3.11.0 (using Ubuntu in a virtual machine)
* Gloo Edge 1.6.15
* Helm 3.5.2

## System Requirements

**You will need at least 12 GB of system memory, otherwise OpenShift may not start up.** If using a virtual machine, increase the size of your memory allocation to the VM.

## Prerequisites

These setup commmands use Homebrew, and work on Mac, Linux, and Windows Subsystem for Linux (WSL).

### Clone Project

```bash
git clone https://github.com/murphye/gloo-quickstarts.git
cd gloo-quickstarts/gloo-edge-openshift-3.11-quickstart
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

#### Install Gloo Edge and Helm CLI

```bash
brew install glooctl
brew install helm
```

## Local OpenShift Cluster

**Docker is required to run the examples.**

### Configure Docker Insecure Registries

Edit your Docker config (i.e. `sudo nano /root/.docker/config.json`) to configure the insecure-registries as such:

```json
{
  "insecure-registries" : [ "172.30.0.0/16" ]
}
```

You will need to restart the Docker service after making this change.

### Unblock or Disable Firewall 

OpenShift may not startup correctly because of the default firewall rules. If there are startup issues, try disabling your firewall.

#### RHEL and Fedora

See https://github.com/openshift/origin/blob/release-3.11/docs/cluster_up_down.md#linux

### Start OpenShift Cluster

This example uses the `oc cluster up` mechanism to run OpenShift 3.11 locally, rather than use Minishift. Run as `sudo` if your user is not in the `docker` group. Otherwise `sudo` not needed

```bash
mkdir -p "$HOME/.occluster"
sudo oc cluster up --base-dir="$HOME/.occluster"
sudo chmod -R 707 ~/.occluster/
```

### Log in as the OpenShift Administrator

```bash
export KUBECONFIG=~/.occluster/openshift-apiserver/admin.kubeconfig

oc login -u system:admin
```

## Install Gloo Edge via `helm`

It is advised to use Helm to install Gloo Edge on OpenShift. 

```bash
oc new-project gloo-system
oc adm policy add-scc-to-group anyuid system:serviceaccounts:gloo-system

helm install gloo gloo/gloo --namespace gloo-system -f values.yaml
```

Take special notice of the `oc adm policy add-scc-to-group` change to give all service account in the `gloo-system` namespace permission to create volumes. Without setting these permissions, there will be several errors.

It will take a moment for Gloo Edge to install and run. You can check with `oc get pods -n gloo-system` to make sure the pods are running. You should also run `glooctl check` to make sure Gloo Edge is running correctly.

---

## TODO #1

Gloo Edge is currently unsettled after the installation. Further research is needed to resolve this matter.

```
Checking deployments... OK
Checking pods... OK
Checking upstreams... OK
Checking upstream groups... OK
Checking auth configs... OK
Checking rate limit configs... OK
Checking secrets... OK
Checking virtual services... OK
Checking gateways... OK
Checking proxies... 1 Errors!
Error: 1 error occurred:
	* Your gateway-proxy is out of sync with the Gloo control plane and is not receiving valid gloo config.
You may want to try using the `glooctl proxy logs` or `glooctl debug logs` commands.
```

## TODO #2

Need to either access the gloo-proxy through a container or expose via the OpenShift Router. More work required to get this working.

---

## Excercise: Install the Petstore Sample Application

```bash
oc new-project petstore
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
* https://github.com/openshift/origin/issues/21420
* https://docs.solo.io/gloo-edge/latest/getting_started
* https://docs.solo.io/gloo-edge/latest/installation/platform_configuration/cluster_setup/#openshift
* https://docs.solo.io/gloo-edge/latest/installation/platform_configuration/cluster_setup/#minishift