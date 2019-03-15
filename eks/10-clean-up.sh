#! /bin/bash -x

export KUBECONFIG=env/kubeconfig.eks

helm list

helm delete --purge minibroker
helm delete --purge susecf-metrics
helm delete --purge susecf-console
helm delete --purge susecf-scf
helm delete --purge susecf-uaa

# remove unused volumes created by pv
aws ec2 describe-volumes --output json | jq '.Volumes[] | .VolumeId' | xargs -I % sh -c "aws ec2 delete-volume --volume-id %"

terraform destroy


