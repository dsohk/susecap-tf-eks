#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "susecap" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "susecap-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "susecap" {
  count = 2

  availability_zone = "${var.aws-az[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.susecap.id}"

  tags = "${
    map(
     "Name", "susecap-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "susecap" {
  vpc_id = "${aws_vpc.susecap.id}"

  tags {
    Name = "susecap-vpc"
  }
}

resource "aws_route_table" "susecap" {
  vpc_id = "${aws_vpc.susecap.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.susecap.id}"
  }
}

resource "aws_route_table_association" "susecap" {
  count = 2

  subnet_id      = "${aws_subnet.susecap.*.id[count.index]}"
  route_table_id = "${aws_route_table.susecap.id}"
}
