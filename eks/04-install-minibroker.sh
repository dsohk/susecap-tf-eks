#! /bin/bash -ex

export KUBECONFIG=env/kubeconfig.eks

helm install suse/minibroker --namespace minibroker --name minibroker  --set "defaultNamespace=minibroker" --wait
helm status minibroker

# wait until minibroker done

cf api --skip-ssl-validation https://api.open-cloud.net
cf login -u admin -p "Demo123$"
cf create-org demo
cf create-space dev -o demo
cf create-space prod -o demo
sleep 30
cf target -o demo -s dev
cf create-service-broker minibroker username password http://minibroker-minibroker.minibroker.svc.cluster.local
cf service-brokers
cf service-access -b minibroker
cf enable-service-access redis
cf enable-service-access mysql
cf enable-service-access postgresql
cf enable-service-access mariadb
cf enable-service-access mongodb
cf marketplace
