#! /bin/bash -ex

export KUBECONFIG=env/kubeconfig.eks

# give tiller sufficient permissions to make changes on eks
kubectl apply -f susecap/rbac-config.yaml
helm init --service-account tiller

helm repo add suse https://kubernetes-charts.suse.com/
helm repo list
helm search suse
