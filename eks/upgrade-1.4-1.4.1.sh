#! /bin/bash

# upgrade from 1.4 to 1.4.1

helm upgrade --recreate-pods --version 2.17.1 susecf-uaa suse/uaa --values susecap/scf-config-values.yaml

SECRET=$(kubectl get pods --namespace uaa \
--output jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
--output jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm upgrade --recreate-pods --reuse-values --version 2.17.1 susecf-scf suse/cf \
  --set "secrets.UAA_CA_CERT=${CA_CERT}"

# no change in stratos from 1.4 to 1.4.1
# helm upgrade --recreate-pods --reuse-values --version susecf-console suse/console
