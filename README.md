# Automated Deployment of SUSE Cloud Application Platform onto AWS EKS

## Deploy EKS with terraform

This script will deploy an EKS cluster in the following region with these instance sizes.
* region: us-east-1
* instance size: 3 xlarge (16GB RAM) worker nodes across different AZs

## Client PC setup (linux, mac, windows)

* Open AWS Account (may require credit card verification)
* Setup admin user with programmatic and console access
** IAM > Add group > admin (with AdminAccess Policy)
** IAM > Add user > enable prog and console access and associate with admin group
** Download credentials CSV
* Install AWS CLI
** Download and install
** Run `aws configure` (input API keys wiith default region to us-east-1)
** Validate aws cli installation with `aws ec2 describe-instances` and expect some output without errors.
* Install kubectl and helm
* Install aws-iam-authenticator
* Install terraform

## Create EKS cluster on your AWS

* create a working folder and download the latest terraform script for creating EKS
** download - https://github.com/dsohk/susecap-tf-eks
* Make sure you run terraform command in your working folder.
* Run `terraform init` to download aws provider plugin for terraform
* Run `terraform plan` to valiate TF files syntax
* Run `terraform apply` to provision resources defined in TF to your AWS account
* Run "terraform output" to list down the output (configmap and kubeconfig)
* Copy the content of configmap into configmap.yaml file
* Copy the content of kubeconfig into kubeconfig.eks file
* Run `KUBECONFIG=kubeconfig.eks kubectl apply -f configmap.yaml` to configure your EKS cluster to be able to authenticate with your AWS IAM.
* At this point, you should be able to use your kubectl to control your EKS cluster. Test with `kubectl get nodes`

## Setup helm repo for SUSE CAP
* Run "helm add repo ...." or "helm repo update" (fetch the latest helm charts)
* Run "helm repo list"
* Run "helm search suse" to list SUSE related helm charts

Refer to SUSE CAP doc to continue the deployment of CAP on your EKS
https://www.suse.com/documentation/cloud-application-platform-1/singlehtml/book_cap_guides/book_cap_guides.html#sec.cap.install-uaa-prod


## Destroy EKS cluster on your AWS

* Run "terraform destroy" to clean up resources provisioned by TF on your AWS account.
