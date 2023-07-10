# Install k3s on master
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --token <pw> --node-taint CriticalAddonsOnly=true:NoExecute --bind-address 192.168.50.220

# Get kube config from master:
cat /etc/rancher/k3s/k3s.yaml

# Install on nodes
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.50.220:6443 K3S_TOKEN=<pw> sh -

# Label Nodes:

kubectl label nodes <node-name> kubernetes.io/role=worker && kubectl label nodes <node-name> node-type=worker
