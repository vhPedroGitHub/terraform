provider "aws" {
    region = "us-east-1"
    access_key = var.acces_key
    secret_key = var.secret_key
}

variable "acces_key" {}
variable "secret_key" {}
variable "cidr_block_vpc" {}
variable "envent_prefix" {}
variable "availability_zone" {}
variable "my_ip" {}
variable "instance_type" {}

# creamos un vpc en nuestro servidor de aws
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.cidr_block_vpc

    tags = {
      Name = "${var.envent_prefix}-vpc"
    }
}

# le agregamos a nuestro vpc una subred
resource "aws_subnet" "myapp-subnet" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.envent_prefix}-subnet"
  }
}

# creamos un gateway hacia internet para nuestro vpc
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id

    tags = {
        Name = "${var.envent_prefix}-igw"
    }
}

resource "aws_default_route_table" "myapp-drt" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name = "${var.envent_prefix}-drt"
    }
}

resource "aws_default_security_group" "myapp-sg" {
    vpc_id = aws_vpc.myapp-vpc.id 

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
      Name = "${var.envent_prefix}-sg"
    }
}   

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["al2023-ami-*-x86_64"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}  

resource "aws_instance" "myapp-image-linux" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet.id
    vpc_security_group_ids = [aws_default_security_group.myapp-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = "pair-pedro-valher"

    user_data = file("script-init.sh")

    tags = {
      Name = "${var.envent_prefix}-server"
    }
}

output "id_ec2" {
    value = aws_instance.myapp-image-linux.public_ip
}