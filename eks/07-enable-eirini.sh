#! /bin/bash -ex

export KUBECONFIG=env/kubeconfig.eks

SECRET=$(kubectl get pods -n uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
echo $SECRET
CA_CERT="$(kubectl get secret $SECRET -n uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
echo $CA_CERT

helm upgrade susecf-scf suse/cf \
--values susecap/scf-config-values.yaml \
--set "enable.eirini=true" \
--set "secrets.UAA_CA_CERT=${CA_CERT}"
