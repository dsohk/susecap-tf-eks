#! /bin/bash

# upgrade from 1.4.1 to 1.5

helm upgrade --recreate-pods --version 2.18 susecf-uaa suse/uaa --values susecap/scf-config-values.yaml

SECRET=$(kubectl get pods --namespace uaa \
--output jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
--output jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm upgrade --recreate-pods --version 2.18 susecf-scf suse/cf \
  --values susecap/scf-config-values.yaml \
  --values susecap/scf-enable-eirini.yaml \
  --set "secrets.UAA_CA_CERT=${CA_CERT}"

helm upgrade --recreate-pods --reuse-values --version 1.5.1 susecf-console suse/console
