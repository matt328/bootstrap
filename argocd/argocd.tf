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
    config_path = "~/.kube/config"
  }
}

# for larger tf projects you'd want this in a separate file but it's literally the only one
# so its just right here
variable "admin_password" {}


# helm is whatever, but the easiest way to install argo is with this helm chart
# defining the admin_password variable in variables.tf will prompt for its entry on the commandline
module "argocd" {
  source         = "aigisuk/argocd/kubernetes"
  admin_password = var.admin_password
}
