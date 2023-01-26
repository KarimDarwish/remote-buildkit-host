resource "aws_vpc" "github_runner" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "github-runner-vpc"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.github_runner.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.subnet_availability_zone

  tags = {
    Name      = "github-runner-private-subnet"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.github_runner.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.subnet_availability_zone

  tags = {
    Name      = "github-runner-public-subnet"
    ManagedBy = "terraform"
  }
}

resource "aws_internet_gateway" "public_gateway" {
  vpc_id = aws_vpc.github_runner.id
  tags = {
    Name      = "github-runner-internet-gateway"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "to_internet" {
  vpc_id = aws_vpc.github_runner.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gateway.id
  }
  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "public_to_internet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.to_internet.id
}

resource "aws_eip" "default" {
  vpc = true

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.default.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name      = "github-runner-nat-gateway"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "to_nat" {
  vpc_id = aws_vpc.github_runner.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "private_to_nat" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.to_nat.id
}

resource "aws_security_group" "default" {
  name        = "github-actions-runner-sg"
  description = "Github Actions Runner Security Group"
  vpc_id      = aws_vpc.github_runner.id

  egress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  #Internal Ping - used for VPN
  egress {
    from_port         = -1
    to_port           = -1
    protocol          = "icmp"
    self = true
  }

  #Internal Ping - used for VPN
  ingress {
    from_port = -1
    protocol  = "icmp"
    to_port   = -1
    self = true
  }

  #Buildkit Internal Ingress
  ingress {
    from_port         = 8082
    to_port           = 8082
    protocol          = "tcp"
    self = true
  }

  #Buildkit Internal Egress
  egress {
    from_port         = 8082
    to_port           = 8082
    protocol          = "tcp"
    self = true
  }

  tags = {
    Name      = "github-runner-security-group"
    ManagedBy = "terraform"
  }
}
