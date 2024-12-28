provider "aws" {
    region = "ap-south-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}

resource "aws_vpc" "development-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
      Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
      Name: "${var.env_prefix}-subnet"
    }
  }

  output "aws_vpc" {
    value = aws_vpc.development-vpc.id
      }

  output "aws_subnet" {
    value = aws_vpc.development-vpc.id
      }

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.development-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-IGE.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_internet_gateway" "my-IGE" {
    vpc_id = aws_vpc.development-vpc.id
    tags = {
      Name = "${var.env_prefix}-IGW"
    }

}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "mysg" {
    name = "mysg"
    vpc_id = aws_vpc.development-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
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
      Name = "${var.env_prefix}-SG"
    }

}


data "aws_ami" "latest-rhel9-image" {
  most_recent = true
  owners      = ["309956199498"]  # Red Hat's AWS account ID
  filter {
    name   = "image-id"
    values = ["ami-022ce6f32988af5fa", "ami-0b0ec21d6b2ce310b"]  # RHEL 9 AMIs (x86 and Arm)
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "my_server" {
        count                      =3
    ami                         = data.aws_ami.latest-rhel9-image.id
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.dev-subnet-1.id
    vpc_security_group_ids      = [aws_security_group.mysg.id]
    availability_zone           = var.avail_zone
    associate_public_ip_address = true
    key_name                    = "server-build"

    tags = {
      Name = "${var.env_prefix}-server"
    }
}
