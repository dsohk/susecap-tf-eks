#! /bin/bash -ex

export KUBECONFIG=env/kubeconfig.eks

# add gp2scoped storage class for stratos
kubectl apply -f susecap/storage-class.yaml

helm install suse/uaa \
--name susecf-uaa \
--namespace uaa \
--values susecap/scf-config-values.yaml \
--values susecap/uaa-sizing.yaml

# fetch the ELB hostnames for all CAP endpoints
UAA_LB="$(kubectl get svc --namespace uaa uaa-uaa-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# wait until all pods are up and running
sleep 5

# notice the CNAME for ELB on uaa-public service
kubectl get services -n uaa -o wide | grep elb

# configure DNS for the domain
# uaa.example.com	uaa/uaa-public
# *.uaa.example.com	uaa/uaa-public

# Because of the way EKS runs health checks,
# Cloud Application Platform requires an edit to one of the scf Helm charts,
# and then after a successful scf deployment remove a listening port from the Elastic Load Balancer's listeners list.
mkdir -p tmp
cp ~/.helm/cache/archive/cf-2.14.5.tgz tmp/cf-2.14.5.tgz
cd tmp
tar xvf cf-2.14.5.tgz
# vi cf/templates/tcp-router.yaml
rm cf-2.14.5.tgz
tar cvzf cf-2.14.5.tgz cf/*
cp ~/.helm/cache/archive/cf-2.14.5.tgz ~/.helm/cache/archive/cf-2.14.5.tgz.orig
cp cf-2.14.5.tgz ~/.helm/cache/archive/cf-2.14.5.tgz
cd ..

# install scf

SECRET=$(kubectl get pods -n uaa -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')
echo $SECRET
CA_CERT="$(kubectl get secret $SECRET -n uaa -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"
echo $CA_CERT

helm install suse/cf \
--name susecf-scf \
--namespace scf \
--values susecap/scf-config-values.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

# wait until all pods are up
sleep 5

# notice the CNAME for ELB on uaa-public service
kubectl get services --namespace scf -o wide | grep elb

GOROUTER_LB="$(kubectl get svc --namespace scf router-gorouter-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
DIEGOSSH_LB="$(kubectl get svc --namespace scf diego-ssh-ssh-proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
TCPROUTER_LB="$(kubectl get svc --namespace scf tcp-router-tcp-router-public -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"


# configure DNS (CNAME)
# example.com	scf/router-gorouter-public
# *.example.com	scf/router-gorouter-public
# tcp.example.com	scf/tcp-router-tcp-router-public
# ssh.example.com	scf/diego-ssh-ssh-proxy-public

helm install suse/console \
    --name susecf-console \
    --namespace stratos \
    --values susecap/scf-config-values.yaml \
    --values susecap/stratos-config-values.yaml

# wait until all pods are up
sleep 5

# configure DNS (CNAME) for Stratos
# console.example.com -> stratos/console-ui-ext

CONSOLE_LB="$(kubectl get svc --namespace stratos console-ui-ext -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
METRICS_LB="$(kubectl get svc --namespace stratos metrics-metrics-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# capture the following info

# EKS API endpoint
aws eks describe-cluster --name susecap-eks --output json | jq '.cluster.endpoint'

# EKS Cluster Name (arn)
aws eks describe-cluster --name susecap-eks --output json | jq '.cluster.arn'

