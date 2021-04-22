# Update the kube server address for the Argo context

# TODO: Change to IP Address for the server, cannot resolve using the Docker embedded DNS
# https://stackoverflow.com/questions/43692961/how-to-get-ip-address-of-running-docker-container
sed -i '' 's/127.0.0.1/server-east/g' kubeconfig-east.yaml
sed -i '' 's/127.0.0.1/server-west/g' kubeconfig-west.yaml

# Todo: expose ArgoCD via metallb?
kubectl --context cluster-central port-forward svc/argocd-server -n argocd 8083:80

# Another terminal
argocd login --username admin --password admin --insecure localhost:8083
argocd cluster add --kubeconfig ./kubeconfig-east.yaml server-east
argocd cluster add --kubeconfig ./kubeconfig-west.yaml server-west