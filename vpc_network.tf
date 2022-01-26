
provider "aws" {
  region                  = "us-west-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "master"
}

# Create a VPC
resource "aws_vpc" "west1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "west1"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.west1.id
}

resource "aws_route_table" "internet_rt" {
  vpc_id = aws_vpc.west1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "vpc_internet_rt"
  }
}

resource "aws_main_route_table_association" "set_vpc_rt" {
  vpc_id         = aws_vpc.west1.id
  route_table_id = aws_route_table.internet_rt.id
}


resource "aws_subnet" "master_public" {
  vpc_id     = aws_vpc.west1.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "master"
  }
}

resource "aws_subnet" "worker_public" {
  vpc_id     = aws_vpc.west1.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "worker"
  }
}

resource "aws_route_table_association" "master_internet_route" {
  subnet_id      = aws_subnet.master_public.id
  route_table_id = aws_route_table.internet_rt.id
}

resource "aws_route_table_association" "worker_internet_route" {
  subnet_id      = aws_subnet.worker_public.id
  route_table_id = aws_route_table.internet_rt.id
}


resource "aws_security_group" "vpc_sg" {
  name   = "vpc_sg"
  vpc_id = aws_vpc.west1.id
  ingress {
    description = "Allow all traffic from port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow from port 22 ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}