# this configures required providers
terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# configure a helm provider.  helm provider uses this .kube config file to
# know which cluster to connect to
provider "helm" {
  kubernetes {
    config_path = "~/.kube/neon-config"
  }
}

# for larger tf projects you'd want this in a separate file but it's literally the only one
# so its just right here
variable "admin_password" {}

# See https://artifacthub.io/packages/helm/argo/argo-cd for latest version(s)
variable "argocd_chart_version" {
  default     = "5.36.7"
  type        = string
  description = "Version of the ArgoCD Helm chart to use"
}

# helm is whatever, but the easiest way to install argo is with this helm chart
# defining the admin_password variable in variables.tf will prompt for its entry on the commandline
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  timeout = 800 # (10 mins) Helm can sometimes take 5 ever.

  set {
    name  = "configs.params.server.insecure"
    value = true
  }

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.admin_password == "" ? "" : bcrypt(var.admin_password)
  }
}
