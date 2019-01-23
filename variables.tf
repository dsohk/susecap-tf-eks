#
# Variables Configuration
#

variable "cluster-name" {
  default = "susecap-eks"
  type    = "string"
}

variable "aws-az" {
  default = ["us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
}

