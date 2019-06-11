#! /bin/bash -ex

terraform init
terraform apply --auto-approve

# enable eks to be authenticable with aws-authenticator
export KUBECONFIG=env/kubeconfig.eks
kubectl apply -f env/configmap.yaml

# give 10 seconds to EKS to initialize its cluster before checking its readiness
sleep 10
kubectl get nodes
