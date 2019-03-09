#! /bin/bash -ex

export KUBECONFIG=env/kubeconfig.eks

helm install suse/metrics \
    --name susecf-metrics \
    --namespace metrics \
    --values susecap/scf-config-values.yaml \
    --values susecap/stratos-config-values.yaml \
    --values susecap/stratos-metrics-values.yaml
