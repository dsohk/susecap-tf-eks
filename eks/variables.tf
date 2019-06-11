#
# Variables Configuration
#

###############
# EKS Cluster #
###############

variable "cluster-name" {
  default = "susecap-eks"
  type    = "string"
}

variable "cluster-min-size" {
  default = 1
}

variable "cluster-max-size" {
  default = 3
}

variable "cluster-instance-type" {
  default = "m4.large"
  type    = "string"
}

variable "aws-az" {
  default = ["us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
}

############
# SUSE CAP #
############

variable "susecap-domain" {
  default = "open-cloud.net"
  type    = "string"
}

variable "susecap-admin-password" {
  default = "Demo123$"
  type    = "string"
}

variable "susecap-admin-client-secret" {
  default = "s3cret"
  type    = "string"
}
