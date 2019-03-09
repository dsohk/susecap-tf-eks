#! /bin/bash -ex

terraform init
terraform apply

# output the config files
mkdir -p env
terraform output kubeconfig > env/kubeconfig.eks
terraform output config_map_aws_auth > env/configmap.yaml

# enable eks to be authenticable with aws-authenticator
export KUBECONFIG=env/kubeconfig.eks
kubectl apply -f env/configmap.yaml

# give 10 seconds to EKS to initialize its cluster before checking its readiness
sleep 10
kubectl get nodes
