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

// https://www.kubestack.com/guides/catalog-using-kubestack-catalog-modules-standalone/
module "argocd_install" {
  source  = "kbst.xyz/catalog/argo-cd"
  version = "v2.6.2-kbst.0"

  configuration = {
    apps = {}
    ops = {
      variant = "normal"
    }
  }

}
