#! /bin/bash -ex

# Updated to deploy SUSE CAP 1.5.2 with embedded uaa approach

# lock down helm chart version
# See: https://documentation.suse.com/suse-cap/1.5.2/html/cap-guides/cha-cap-depl-notes.html#id-1.3.4.3.10
export HELM_SCF_VER=2.20.3
export HELM_STRATOS_VER=2.7.0
export HELM_METRICS_VER=1.1.2

export SCF_DOMAIN=open-cloud.net
export KUBECONFIG=env/kubeconfig.eks

# ###############################
# Setup Storage Class (gp2scoped)
# ###############################

# add gp2scoped storage class for stratos
kubectl apply -f susecap/storage-class.yaml

# ##############################################
# Setup Cloudflare client - automating DNS Setup
# ##############################################

# install Cloudflare client if it does not exist
# https://github.com/cloudflare/cloudflare-go/tree/master/cmd/flarectl
# go get -u github.com/cloudflare/cloudflare-go/...

# load Cloudflare API credentials
source ~/.cloudflare/credentials

# #####################
# Setup SUSECAP - SCF #
# #####################

helm install suse/cf \
--name susecf-scf \
--version $HELM_SCF_VER \
--namespace scf \
--values susecap/scf-config-values.yaml

# If you have enabled eirini, remember to run the follow command to finish setting up secret.
# See: https://documentation.suse.com/suse-cap/1.5.1/single-html/cap-guides/#sec-cap-eirini-enable
export POD_SECRET_GENERATION=`kubectl get pods -n scf -ojsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' -l skiff-role-name=secret-generation`
kubectl logs pod/${POD_SECRET_GENERATION} -n scf  # check the log until it says "waiting for ssl cert approval"
kubectl certificate approve scf-bits-service-ssl-cert

read -p 'Please run watch -c "kubectl get pod -n scf" in another session. Press [Enter] key to it is ready...'

# kubectl get svc -n scf | grep LoadBalancer
# eirini-ssh-eirini-ssh-proxy-public          LoadBalancer   172.20.207.226   a10c85727473b11eaafaa0e5cf73bcb8-1028633194.us-east-1.elb.amazonaws.com   2222:31733/TCP                                                                                                                                    15h
# router-gorouter-public                      LoadBalancer   172.20.17.242    a10e6dfdd473b11eaafaa0e5cf73bcb8-383828521.us-east-1.elb.amazonaws.com    80:31372/TCP,443:30549/TCP                                                                                                                        15h
# tcp-router-tcp-router-public                LoadBalancer   172.20.162.9     a10f43d13473b11eaafaa0e5cf73bcb8-2067356858.us-east-1.elb.amazonaws.com   20000:30550/TCP,20001:32690/TCP,20002:32461/TCP,20003:30880/TCP,20004:31122/TCP,20005:32355/TCP,20006:30889/TCP,20007:31949/TCP,20008:31154/TCP   15h
# uaa-uaa-public                              LoadBalancer   172.20.32.111    a10bba66f473b11eaafaa0e5cf73bcb8-1112881382.us-east-1.elb.amazonaws.com   2793:32741/TCP                                                                                                                                    15h

# capture AWS LB end points for DNS CNAME Setup
export GOROUTER_LB="$(kubectl get svc --namespace scf router-gorouter-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
export EIRINISSH_LB="$(kubectl get svc --namespace scf eirini-ssh-eirini-ssh-proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
# DIEGOSSH_LB="$(kubectl get svc --namespace scf diego-ssh-ssh-proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
export TCPROUTER_LB="$(kubectl get svc --namespace scf tcp-router-tcp-router-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
export UAA_LB="$(kubectl get svc --namespace scf uaa-uaa-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS in cloudflare
## flarectl dns create-or-update doesn't support root records
## https://github.com/cloudflare/cloudflare-go/issues/206
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '$SCF_DOMAIN' --content "$GOROUTER_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*.uaa' --content "$UAA_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'uaa' --content "$UAA_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name '*' --content "$GOROUTER_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'ssh' --content "$EIRINISSH_LB"
# flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'ssh' --content "$DIEGOSSH_LB"
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'tcp' --content "$TCPROUTER_LB"

# ###################
# SUSECAP - STRATOS #
# ###################

helm install suse/console \
--name susecf-console \
--version $HELM_STRATOS_VER \
--namespace stratos \
--set console.techPreview=true \
--set console.migrateVolumes=false \
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
--version $HELM_METRICS_VER \
--namespace metrics \
--values susecap/scf-config-values.yaml \
--values susecap/stratos-metrics-values.yaml \
--set "kubernetes.apiEndpoint=${EKS_EP}" \
--set args[0]="--kubelet-preferred-address-types=InternalIP" \
--set args[1]="--kubelet-insecure-tls"

read -p 'Please run watch -c "kubectl get pod -n metrics" in another session. Press [Enter] key to it is ready...'

METRICS_LB="$(kubectl get svc --namespace metrics susecf-metrics-metrics-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# configure DNS (CNAME) for Stratos
flarectl dns create-or-update --zone $SCF_DOMAIN --type CNAME --name 'metrics' --content "$METRICS_LB"

# EKS Cluster Name (arn)
# aws eks describe-cluster --name susecap-eks --output json | jq '.cluster.arn'

