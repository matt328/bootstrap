terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.0"
    }
  }
}

provider "kustomization" {
  // kubeconfig_path = "~/.kube/neon-config"
  kubeconfig_path = "C:/Users/Matt/.kube/neon-config"
}

module "argocd_install" {
  source  = "kbst.xyz/catalog/argo-cd/kustomization"
  version = "2.6.7-kbst.0"

  configuration_base_key = "default"

  configuration = {
    default = {
      additional_resources = ["${path.root}/manifests/traefik-ingress.yml"]
      config_map_generator = [{
        name      = "argocd-cmd-params-cm"
        namespace = "argocd"
        behavior  = "merge"
        literals = [
          "server.insecure=true"
        ]
      }]
      variant = "normal"
    }
  }
}

// After doing this, you have to kubectl apply something like this https://github.com/JuanWigg/self-managed-argo/blob/main/applications.yaml
// which defines (a potentially different version of) argocd to be managed by itself from now on.  The intially installed instance of argo
// is almost a temporary bootstrapper that might get overwritten by itself.
