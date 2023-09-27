# k3s Homelab

This repository serves as a 'live' repository for a k3s based homelab used for learning exercises with kubernetes
and devops topics in general. The tools and technologies used include:

## Infrastructure

- k3s - fairly simple way to get a kubernetes cluster with multiple nodes set up
- MetalLB - Loadbalancing for application access is something a cloud provider normally provides, but since this is using resources on my local network, MetalLB enables mapping local IP addresses directly to services running inside the cluster.
- Longhorn - enables fairly straightforward configuration of persistence options in the cluster. Manages persistent volumes and persistent volume claims and provides scheduled backups, and more importantly restoration of said backups.
- Bitnami Sealed Secrets - a 'good enough' utility that allows a declarative approach to secrets management.
- ArgoCD - Allows declarative management of tools as well as any applications deployed into the cluster.

## Monitoring

- Grafana's LGTM stack - Not very lightweight, but provides a 'single pane of glass' view into all things observability related.

## Applications

- Gitea - lightweight github clone, allows private, on prem hosting of git projects. A great exercise in deploying and maintaining an application that utilizes persistent storage with longhorn.

# Break Glass / Initial Setup

## k3s

1. Install k3s on the master node:

   ```sh
   curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --token <pw> --node-taint CriticalAddonsOnly=true:NoExecute --bind-address <public IP address> --disable=traefik --disable=servicelb
   ```

1. Get the kube config from the master to configure kubectl on another machine

   ```sh
   cat /etc/rancher/k3s/k3s.yaml
   ```

1. Install k3s on each node:

   ```sh
   curl -sfL https://get.k3s.io | K3S_URL=https://<master node IP address>:6443 K3S_TOKEN=<pw> sh -
   ```

1. (Optional) Label Nodes
   ```sh
   kubectl label nodes <node-name> kubernetes.io/role=worker
   kubectl label nodes <node-name> node-type=worker
   ```

## MetalLB

1. Use kustomize to generate deployment yaml
   ```sh
   kubectl kustomize manifests/metallb >metallb-deployment.yaml
   ```
1. Review generated yaml for correctness.
1. Deploy into k3s:
   ```sh
   kubectl apply -f metallb-deployment.yaml
   ```
   With MetalLB controller deployed, we can now just deploy a kubernetes Service resource with the type of `Loadbalancer` and MetalLB will see to the service being mapped to an IP address from the defined pool.

## Sealed Secrets Controller

```sh
kubectl kustomize --enable-helm manifests/tools/sealed-secrets > sealed-secrets-deployment.yaml
# Verify yaml contents
kubectl apply -f sealed-secrets-deployment.yaml
```

## ArgoCD Bootstrap

This configuration is inspired by the ArgoCD docs themselves, particularly

- https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#manage-argo-cd-using-argo-cd
- https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/

The `tools` group uses an ApplicationSet:

- https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/

The overall idea is to have everything that runs in kubernetes declaratively managed by ArgoCD, including ArgoCD itself, which presents a chicken and the egg situation: How does ArgoCD get installed in the first place? The `Break Glass` steps above illustrate step by step how to bootstrap a cluster, but the general idea is you have to install a few items manually, via `kubectl apply`, and once those are in place, you add their manifest directories as Projects inside of ArgoCD, and it will start to monitor them from there. From then on, to modify or update any of those applications and configurations, you simply push changes to the repository, and ArgoCD will sync them to the cluster. ArgoCD will deploy applications via the same mechanism, although to make roles and permissions management easier, applications developers deploy would be stored in a separate repository from the kubernetes infrastructure applications and configuration.

1. Create and seal the argo repo secret

   - The ArgoCD kustomization requires a sealed secret that ArgoCD will use to communicate with the git repos containing the application manifests it will keep in sync with k8s. An unsealed secret needs to be created first
     of the form:

     ```yaml
     apiVersion: v1
     kind: Secret
     metadata:
       name: <secret-name>
       namespace: argocd
       labels:
         argocd.argoproj.io/secret-type: repository
       annotations:
         sealedsecrets.bitnami.com/managed: "true"
     stringData:
       type: git
       url: <git@github.com:account/repository>
       username: <username>
       password: <gitlab access token>
     ```

   - Note that the URL should point to the `bootstrap` repository itself in this example.
   - The password should be a github personal access token with at least read repository permissions.
   - Sealed secrets require a k8s cluster to be established first, the kubeseal command below will use a secret from the k8s control plane as an encryption key or something to that effect, that's why there are no sealed secrets present initially.
   - Create the unsealed secret yaml file
   - Run kubeseal to seal the secret, put the sealed secret in the `manifests/argocd` folder so the kustomization can reference it.

     ```sh
     kubeseal --format yaml secret.yaml >manifests/argocd/sealed-secret.yaml
     ```

     or

     ```powershell
     Get-Content .\secret.yaml | kubeseal --format yaml >.\manifests\argocd\sealed-secret.yaml
     ```

1. Install argo manually
   - Make sure the secret has been updated in the file `manifests/argocd/sealed-secret.yaml`
   - Apply the kustomized manifests:
     ```sh
     kubectl kustomize --enable-helm manifests/argocd >argocd-deployment.yaml
     # Verify yaml
     kubectl apply -f argocd-deployment.yaml
     ```
   - Verify all the ArgoCD pods have started up.
1. Take over both sealed-secrets controller and ArgoCD by installing both the ArgoCD and Tools namespace root applications.
   ```sh
   kubectl apply -f root-apps/argocd.yaml
   kubectl apply -f root-apps/tools.yaml
   ```

# Longhorn

Longhorn is kind of a snowflake in my cluster since IMO it abuses helm hooks and ArgoCD has a tough time deploying it. Also, IMO Longhorn in general can't be deployed declaratively, it follows too closely a clickopsy maintenance paradigm reminiscient of the old InstallShield wizards back in the day. But, alas, it does provide application independent backup and restore of persistent volumes.

In order to install Longhorn, for now I'll run kustomize on it's folder and apply the generated yaml. Eventually I should just give in and `helm install` it manually like they want you to do.

```sh
kubectl kustomize --enable-helm manual-apps/longhorn >longhorn-deployment.yaml
# Verify yaml
kubectl apply -f longhorn-deployment.yaml
```

I currently have no idea what the upgrade process for Longhorn looks like since they really want you to just clickops it by installing and upgrading it with its helm chart, so we'll have to cross that bridge when we come to it. Watching k9s while longhorn is being 'installed' I really want to find a simpler way to backup persistent volumes

# Maintain Tools

Should be able to just push changes to the manifests repo(s) in order for things to update.
