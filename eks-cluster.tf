#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "susecap-cluster" {
  name = "susecap-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "susecap-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.susecap-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "susecap-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.susecap-cluster.name}"
}

resource "aws_security_group" "susecap-cluster" {
  name        = "susecap-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.susecap.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "susecap-eks"
  }
}

resource "aws_security_group_rule" "susecap-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.susecap-cluster.id}"
  source_security_group_id = "${aws_security_group.susecap-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "susecap-cluster-ingress-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow ingress traffic to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.susecap-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "susecap" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.susecap-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.susecap-cluster.id}"]
    subnet_ids         = ["${aws_subnet.susecap.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.susecap-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.susecap-cluster-AmazonEKSServicePolicy",
  ]
}
