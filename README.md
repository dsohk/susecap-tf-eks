# Automated Deployment of SUSE Cloud Application Platform onto AWS EKS

## Deploy EKS with terraform

This script will deploy an EKS cluster in the following region with these instance sizes.
* region: us-east-1
* instance size: 3 xlarge (16GB RAM) worker nodes across different AZs

## Client PC setup (linux, mac, windows)

* Open AWS Account (may require credit card verification)
* Setup admin user with programmatic and console access
  * IAM > Add group > admin (with AdminAccess Policy)
  * IAM > Add user > enable prog and console access and associate with admin group
  * Download credentials CSV
* Install AWS CLI
  * Download and install
  * Run `aws configure` (input API keys wiith default region to us-east-1)
  * Validate aws cli installation with `aws ec2 describe-instances` and expect some output without errors.
* Install kubectl and helm
* Install aws-iam-authenticator
* Install terraform

## Create EKS cluster on your AWS

Run the build script to create your EKS cluster on your AWS.

```
git clone https://github.com/dsohk/susecap-tf-eks.git
cd susecap-tf-eks
cd eks
./01-build-eks.sh
```

## Setup helm repo for SUSE CAP

After the above step is finished, run the following script to get your helm chart
ready.

```
./02-config-helm.sh
```

## Install SUSE CAP (uaa + scf + stratos)

(Working in progress)

```
./03-install-susecap.sh
```

## Install metrics

(Working in progress)

```
./04-install-metrics.sh
```

## Install minibrokers

(Working in progress)

```
./05-install-minibroker.sh
```

Refer to SUSE CAP doc to continue the deployment of CAP on your EKS
https://www.suse.com/documentation/cloud-application-platform-1/singlehtml/book_cap_guides/book_cap_guides.html#sec.cap.install-uaa-prod


## Destroy EKS cluster on your AWS

* Run `terraform destroy` to clean up resources provisioned by terraform on your AWS account.
