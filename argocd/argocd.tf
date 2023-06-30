terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.0"
    }
  }
}

provider "kustomization" {
  kubeconfig_path = "~/.kube/neon-config"
}

module "argocd_install" {
  source  = "kbst.xyz/catalog/argo-cd/kustomization"
  version = "v2.6.7-kbst.0"

  configuration_base_key = "default"

  configuration = {
    default = {
      config_map_generator = [{
        name = "argocd-cmd-params-cm"
        namespace = "argocd"
        behavior = "merge"
        literals = [
          "server.insecure=true"
        ]
      }]
      variant = "normal"
    }
  }
}
