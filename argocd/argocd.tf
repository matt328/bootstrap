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

data "kustomization" "current" {
  path = "k8s"
}

resource "kustomization_resource" "current" {
  for_each = data.kustomization.current.ids

  manifest = data.kustomization.current.manifests[each.value]
}
