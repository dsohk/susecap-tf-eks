#! /bin/bash -ex

export SCF_DOMAIN=open-cloud.net
export KUBECONFIG=env/kubeconfig.eks

# install Cloudflare client if it does not exist
# https://github.com/cloudflare/cloudflare-go/tree/master/cmd/flarectl
# go get -u github.com/cloudflare/cloudflare-go/...

# load Cloudflare API credentials
source ~/.cloudflare/credentials

# fetch the ELB hostnames for all CAP endpoints
UAA_LB="$(kubectl get svc --namespace uaa uaa-uaa-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS for the domain
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*.uaa' --content "$UAA_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'uaa' --content "$UAA_LB"

GOROUTER_LB="$(kubectl get svc --namespace scf router-gorouter-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
# disable diegossh (not used in eirini)
# DIEGOSSH_LB="$(kubectl get svc --namespace scf diego-ssh-ssh-proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
TCPROUTER_LB="$(kubectl get svc --namespace scf tcp-router-tcp-router-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME)
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name "$SCF_DOMAIN" --content "$GOROUTER_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*' --content "$GOROUTER_LB"
# flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'ssh' --content "$DIEGOSSH_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'tcp' --content "$TCPROUTER_LB"

CONSOLE_LB="$(kubectl get svc -n stratos susecf-console-ui-ext -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME) for Stratos
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'console' --content "$CONSOLE_LB"

