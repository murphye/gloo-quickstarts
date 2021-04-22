# Update the contexts to be unique
sed -i '' 's/default/cluster-east/g' kubeconfig-east.yaml
sed -i '' 's/default/cluster-central/g' kubeconfig-central.yaml
sed -i '' 's/default/cluster-west/g' kubeconfig-west.yaml

# Merge the Kubeconfig
# Ref https://ahmet.im/blog/mastering-kubeconfig/
cp $HOME/.kube/config $HOME/.kube/config.backup.$(date +%Y-%m-%d.%H:%M:%S)
KUBECONFIG=kubeconfig-east.yaml:kubeconfig-central.yaml:kubeconfig-west.yaml:$HOME/.kube/config kubectl config view --merge --flatten > ~/.kube/merged_kubeconfig && mv ~/.kube/merged_kubeconfig ~/.kube/config