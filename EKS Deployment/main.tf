terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    #kubernet service
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.34.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
#machine creation
resource "aws_instance" "eksmachine" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  #key_name      = var.key_name
  security_groups = [aws_security_group.webdep_sg.id]
  subnet_id = aws_subnet.pubsubnet.id
}

#craete a security group
resource "aws_security_group" "webdep_sg" {
  name        = "webdeb-sg"
  vpc_id      = aws_vpc.ekcvpc.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows inbound traffic from anywhere
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows outbound traffic to anywhere
  }
}
# Create a VPC
resource "aws_vpc" "ekcvpc" {
  cidr_block = "10.0.0.0/16"
  #  tags = {
  #   Name = "vpc"
  # }
}
#publicsubnet creation
resource "aws_subnet" "pubsubnet" {
  vpc_id     = aws_vpc.ekcvpc.id
  cidr_block = "10.0.1.0/24"
  #availability_zone = "us-east-1b"
  tags = {
    Name = "publicsubnet"
  }
}
#publicsubnet creation
resource "aws_subnet" "prisubnet" {
  vpc_id     = aws_vpc.ekcvpc.id
  cidr_block = "10.0.2.0/24"
  #availability_zone = "us-east-1b"
  tags = {
    Name = "privatelicsubnet"
  }
}
#internetgateway cration
resource "aws_internet_gateway" "igwmy" {
  vpc_id = aws_vpc.ekcvpc.id  #
  tags = {
    Name = "gatewayterraform"
  }
}
#route table creation
resource "aws_route_table" "routetb" {
  vpc_id = aws_vpc.ekcvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwmy.id  #attached with inernet gateway
  }
  tags = {
    Name = "routetabledeploy"
  }
}
#subnet association
resource "aws_route_table_association" "allm" {
 subnet_id  = aws_subnet.pubsubnet.id  # subent association
 route_table_id = aws_route_table.routetb.id  #routetable Association
}
#ecr creation
resource "aws_ecr_repository" "ecrdep" {
        name = "repository"
        image_tag_mutability = "MUTABLE"
        image_scanning_configuration {
          scan_on_push = true
        }
    }

#eks creation
resource "aws_eks_cluster" "eks_cluster" {
  role_arn = "arn:aws:iam::539935451710:user/Group1-HU2"
  name= "eks_cluster"
  version = "1.27"
  vpc_config {
    subnet_ids = [aws_subnet.pubsubnet.id, aws_subnet.prisubnet.id]
    endpoint_public_access = true
  }
}
#i am role for eks 
resource "aws_iam_role" "eks_cluster_role" {
          name                = "eks-cluster-role"
          assume_role_policy  = jsonencode({
            "Version" : "2012-10-17",
            "Statement" : [
              {
                "Action" : "sts:AssumeRole",
                "Principal" : {
                  "Service" : "eks.amazonaws.com"
                },
                "Effect" : "Allow",
                "Sid" : ""
              }
            ]
          })
        }
  resource "aws_security_group" "eks_cluster_sg" {
          name        = "eks-cluster-sg"
          description = "Allow access to control plane"
          vpc_id      = aws_vpc.ekcvpc.id 
        }
