terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.10.0"
    }
  }
}


#########Create Two VPC#######
resource "aws_vpc" "prod" {
  cidr_block = "10.64.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_vpc" "non-prod" {
  cidr_block = "10.76.0.0/16"
  enable_dns_hostnames = true
}

#######create one subnet in each VPC###
resource "aws_subnet" "Prod-LAN" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = "10.64.1.0/24"
}

resource "aws_subnet" "Non-Prod-LAN" {
  vpc_id     = aws_vpc.non-prod.id
  cidr_block = "10.76.1.0/24"
}

######## create internet gateway for each vpc#######
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod.id
}

resource "aws_internet_gateway" "non-prod-igw" {
  vpc_id = aws_vpc.non-prod.id
}

#######create Route table for each VPC#########
resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }
}

resource "aws_route_table" "non-prod-rt" {
  vpc_id = aws_vpc.non-prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.non-prod-igw.id
  }
}

# create route table asso######
resource "aws_route_table_association" "prod-asso" {
  subnet_id = aws_subnet.Prod-LAN.id
  route_table_id = aws_route_table.prod-rt.id
  
}

resource "aws_route_table_association" "non-prod-asso" {
  subnet_id = aws_subnet.Non-Prod-LAN.id
  route_table_id = aws_route_table.non-prod-rt.id
}


######Create EC2 instance for each VPC"
resource "aws_instance" "prod-vm" {
  ami           = "ami-07e70003c665fb5f3"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Prod-LAN.id
  associate_public_ip_address = "true"
  key_name   = "prodkey"
  vpc_security_group_ids = [ aws_security_group.prod-sg.id ]
}

resource "aws_instance" "non-prod-vm" {
  ami           = "ami-07e70003c665fb5f3"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.Non-Prod-LAN.id
  associate_public_ip_address = "true"
  key_name   = "non-prodkey"
  vpc_security_group_ids = [ aws_security_group.non-prod-sg.id ]
}

#####create security group#######
resource "aws_security_group" "prod-sg" {
  name        = "prod-sg"
  description = "allow all traffic"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "allow inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "non-prod-sg" {
  name        = "non-prod-sg"
  description = "allow all traffic"
  vpc_id      = aws_vpc.non-prod.id

  ingress {
    description = "allow inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks  = ["0.0.0.0/0"]
  }
}