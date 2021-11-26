terraform {
    required_version = ">= 0.12"
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = "eu-central-1b"

  tags = {
    Name = "prod_subnet"
  }
}

resource "aws_instance" "web-server-instance" {
  ami               = var.ami #"ami-047e03b8591f2d48a"
  instance_type     = var.instance_type
  availability_zone = "eu-central-1b"
  key_name          = "ec2-mainkey"

  tags = {
      Name = "${var.webserver_name} webserver"
  }
}

