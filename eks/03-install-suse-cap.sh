#! /bin/bash -ex

export SCF_DOMAIN=open-cloud.net
export KUBECONFIG=env/kubeconfig.eks

# add gp2scoped storage class for stratos
kubectl apply -f susecap/storage-class.yaml

# install Cloudflare client if it does not exist
# https://github.com/cloudflare/cloudflare-go/tree/master/cmd/flarectl
# go get -u github.com/cloudflare/cloudflare-go/...

# load Cloudflare API credentials
source ~/.cloudflare/credentials


# #########################
# CREATE EIRINI NAMESPACE #
# #########################

# create eirini namespace
kubectl create -f - <<< '{"kind": "Namespace","apiVersion": "v1","metadata": {"name": "eirini","labels": {"name": "eirini"}}}'

# ###############
# SUSECAP - UAA #
# ###############

helm install suse/uaa \
--name susecf-uaa \
--namespace uaa \
--values susecap/scf-config-values.yaml

read -p 'Please run watch -c "kubectl get pod -n uaa" in another session. Press [Enter] key to it is ready...'

# fetch the ELB hostnames for all CAP endpoints
UAA_LB="$(kubectl get svc --namespace uaa uaa-uaa-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS for the domain
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*.uaa' --content "$UAA_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'uaa' --content "$UAA_LB"

# ###############
# SUSECAP - SCF #
# ###############

SECRET=$(kubectl get pods -n uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
echo $SECRET
CA_CERT="$(kubectl get secret $SECRET -n uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
echo $CA_CERT

helm install suse/cf \
--name susecf-scf \
--namespace scf \
--values susecap/scf-config-values.yaml \
--values susecap/scf-enable-eirini.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

read -p 'Please run watch -c "kubectl get pod -n scf" in another session. Press [Enter] key to it is ready...'

GOROUTER_LB="$(kubectl get svc --namespace scf router-gorouter-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
# disable diegossh (not used in eirini)
# DIEGOSSH_LB="$(kubectl get svc --namespace scf diego-ssh-ssh-proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
TCPROUTER_LB="$(kubectl get svc --namespace scf tcp-router-tcp-router-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME)
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '$SCF_DOMAIN' --content "$GOROUTER_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*' --content "$GOROUTER_LB"
# flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'ssh' --content "$DIEGOSSH_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'tcp' --content "$TCPROUTER_LB"

# ###################
# SUSECAP - STRATOS #
# ###################

helm install suse/console \
--name susecf-console \
--namespace stratos \
--values susecap/scf-config-values.yaml \
--values susecap/stratos-config-values.yaml

read -p 'Please run watch -c "kubectl get pod -n stratos" in another session. Press [Enter] key to it is ready...'

CONSOLE_LB="$(kubectl get svc -n stratos susecf-console-ui-ext -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME) for Stratos
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'console' --content "$CONSOLE_LB"

# ###################
# SUSECAP - METRICS #
# ###################

# EKS End Point
EKS_EP="$(aws eks describe-cluster --name susecap-eks --output json | jq '.cluster.endpoint')"

helm install suse/metrics \
--name susecf-metrics \
--namespace metrics \
--values susecap/scf-config-values.yaml \
--values susecap/stratos-config-values.yaml \
--values susecap/stratos-metrics-values.yaml \
--set "kubernetes.authEndpoint=$EKS_EP"

read -p 'Please run watch -c "kubectl get pod -n metrics" in another session. Press [Enter] key to it is ready...'

METRICS_LB="$(kubectl get svc --namespace metrics susecf-metrics-metrics-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME) for Stratos
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'metrics' --content "$METRICS_LB"

# EKS Cluster Name (arn)
# aws eks describe-cluster --name susecap-eks --output json | jq '.cluster.arn'

