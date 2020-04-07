#
# Provider Configuration
#

terraform {

  required_version = ">= 0.12"

  required_providers {
    aws = "~> 2.56"
    helm = "~> 1.1"
    kubernetes = "~> 1.11"
    local = "~> 1.4"
  }

}


provider "aws" {
  region = "us-east-1"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

provider "kubernetes" {
  config_path = "${path.module}/env/kubeconfig.eks"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/env/kubeconfig.eks"
  }
}
