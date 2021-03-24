# Istio Gloo Portal Quickstart

## About this Quickstart

This Quickstart is intended to show how to use Gloo Portal with Istio Ingress.

## Time to Complete

This will take you **under 5 minutes**.

## Tested With

* k3d 4.3.0
* MetalLB 0.9.5
* Gloo Edge 1.6.15

## Prerequisites

These setup commmands use Homebrew, and work on Mac, Linux, and Windows Subsystem for Linux (WSL).

### Clone Project

```bash
git clone https://github.com/murphye/gloo-quickstarts.git
cd gloo-quickstarts/istio-gloo-portal-quickstart
```

### Install Homebrew
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Command Line Tools (as needed)
```bash
brew install kubernetes-cli
brew install istioctl
brew install k3d
brew install helm
```

## Local Kubernetes Cluster

**Docker is required to run the examples.**

### Start k3d Cluster

This Kubernetes Cluster uses [k3d](http://k3d.io) and [MetalLB](https://metallb.universe.tf/) for a small, stateful development environment that is tuned for this particular Quickstart.

```bash
bash cluster-up.sh istio-gloo-portal-quickstart
```

It will take a brief moment for MetalLB to install and run. You can check with `kubectl get pods -n metallb-system` to make sure the pods are running.

## Install Istio with Istio Ingress via `istioctl` and the Istio Operator

For this Quickstart we just need a basic installation of Istio and Istio Ingress.

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
Verify the installation:

```
kubectl get pods -n istio-system
```

### Enable Istio Injection

```
kubectl label namespace default istio-injection=enabled --overwrite
```

## Install the Petstore Sample Application

```
kubectl apply -n default -f https://raw.githubusercontent.com/solo-io/gloo/v1.3.7/example/petstore/petstore.yaml
kubectl -n default rollout status deployment petstore
```

## Create an Istio Gateway

```
kubectl apply -n istio-system -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-ingressgateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "petstore.com"
EOF
```

## Configure the Istio Gateway Route

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: petstore
spec:
  hosts:
  - "petstore.com"
  gateways:
  - istio-system/istio-ingressgateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 8080
        host: petstore
EOF
```

Check that the route is working:
```
curl -HHost:petstore.com http://localhost/api/pets
``` 

Expected result is:

```
[{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
```

## Install Gloo Portal via `helm` (Gloo Portal License Key Required)

```
helm repo add dev-portal https://storage.googleapis.com/dev-portal-helm
helm repo update
```

```bash
kubectl create namespace dev-portal
helm install dev-portal dev-portal/dev-portal -n dev-portal --set istio.enabled=true --set licenseKey.value=LICENSE_HERE
```
Verify the install:

```
kubectl get all -n dev-portal
```


## Create an API Document

```
cat <<EOF | kubectl apply -f -
apiVersion: devportal.solo.io/v1alpha1
kind: APIDoc
metadata:
  name: petstore-schema
  namespace: default
spec:
  ## specify the type of schema provided in this APIDoc.
  ## openApi is only option at this time.
  openApi:
    content:
      # we use a fetchUrl here to tell the Gloo Portal
      # to fetch the schema contents directly from the petstore service.
      # 
      # configmaps and inline strings are also supported.
      fetchUrl: http://petstore.default:8080/swagger.json

EOF
```

Check the status:

```
kubectl get apidoc -n default petstore-schema -oyaml
```

## Create an API Product

```
cat << EOF | kubectl apply -f -
apiVersion: devportal.solo.io/v1alpha1
kind: APIProduct
metadata:
  name: petstore-product
  namespace: default

spec:
  displayInfo: 
    description: Petstore Product
    title: Petstore Product
    
  # Specify one or more version objects that will each include a list
  # of APIs that compose the version and routing for the version  
  versions:
  - name: v1
    apis:
    # Specify the API Doc(s) that will be included in the Product
    # each specifier can include a list of individual operations
    # to import from the API Doc.
    #
    # If none are listed, all the 
    # operations will be imported from the doc. 
    - apiDoc:
        name: petstore-schema
        namespace: default
      openApi: {}
  
    # Each imported operation must have a 'route' associated with it.
    # Routes can be specified on each imported operation, in the API Doc itself.
    # The Default Route provided here will be used for any operations which do not have a route defined.
    # A route must be provided for every Operation to enable routing for an API Product.  
    defaultRoute:
      inlineRoute:
        backends:
        - kube:
            name: petstore
            namespace: default
            port: 8080
    tags:
      stable: {}
EOF
```

## Create an Environment

```
cat << EOF | kubectl apply -f -
apiVersion: devportal.solo.io/v1alpha1
kind: Environment
metadata:
  name: dev
  namespace: default
spec:
  domains:
  - api.petstore.com
  displayInfo:
    description: This environment is meant for developers to deploy and test their APIs.
    displayName: Development
  apiProducts:
  - name: petstore-product
    namespace: default
    publishedVersions:
    - name: v1
EOF
```

At this point you can check the status of the VirtualServices to make sure `dev` was created correctly:

```
kubectl get virtualservice
NAME       GATEWAYS                              HOSTS               AGE
dev        [istio-system/istio-ingressgateway]   [api.example.com]   2m59s
petstore   [istio-system/istio-ingressgateway]   [petstore.com]      85m
```

## Next Steps

Please see the [Gloo Portal Guide](https://docs.solo.io/gloo-portal/latest/setup/istio/) for more information.

## Wrapping Up

### Stop k3d Cluster

This will retain the cluster state, rather than destroy it.

```bash
k3d cluster stop istio-gloo-portal-quickstart
```

### Restart k3d Cluster

This will restart the cluster to its previous state.

```bash
k3d cluster start istio-gloo-portal-quickstart
```

### Delete k3d Cluster

This will permanently delete the cluster.

```bash
k3d cluster delete istio-gloo-portal-quickstart
```

## References

* https://k3d.io
* https://metallb.universe.tf
* https://docs.solo.io/gloo-portal/latest/setup/istio/