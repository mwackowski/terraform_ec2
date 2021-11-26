provider "aws" {
  region = "eu-central-1"
  access_key = var.access_key
  secret_key = var.secret_key
}


# module "my_webserver_module" {
#     source      = ".//modules/webserver"
#     vpc_id      = aws_vpc.prod-vpc.id
#     cidr_block  = "10.0.0.0/16"
#     webserver_name = "mwackowski"
#     ami = "ami-047e03b8591f2d48a"
# }



# /*
# resource "aws_elb" "main" {
#   instances = module..my_webserver_module.instance.id
# }
# */
# output "instance_data" {
#     value = module.my_webserver_module.instance
# }
# 1. Create vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}
# 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a Subnet 

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = "eu-central-1b"

  tags = {
    Name = "prod_subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami               = "ami-047e03b8591f2d48a"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1b"
  key_name          = "key_pair_pem"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
                sudo yum install -y httpd
                sudo systemctl start httpd
                sudo bash -c 'echo Hello world > /var/www/html/index.html'
                EOF
                
  tags = {
    Name = "web-server"
  }
}

## Create S3

resource "aws_s3_bucket" "my-s3-bucket" {
  bucket_prefix = var.bucket_prefix
  acl = var.acl
  
   versioning {
    enabled = var.versioning
  }
  
  tags = var.tags
}





##################################################################################################

# # VPC
# resource "aws_vpc" "terra-vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "production-vpc"
#   }
# }

# # INTERNET GATEWAY
# resource "aws_internet_gateway" "terra-gateway" {
#   vpc_id = aws_vpc.terra-vpc.id

#   tags = {
#     Name = "production-gateway"
#   }
# }

# # ROUTE TABLE
# resource "aws_route_table" "terra-route-table" {
#   vpc_id = aws_vpc.terra-vpc.id

#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.terra-gateway.id
#     }
#     route {
#         ipv6_cidr_block        = "::/0"
#         gateway_id = aws_internet_gateway.terra-gateway.id
#     }

#   tags = {
#     Name = "prod"
#   }
# }

# # Subnet
# resource "aws_subnet" "subnet-1" {
#   vpc_id            = aws_vpc.terra-vpc.id
#   cidr_block        = "10.0.0.0/24"
#   availability_zone = "eu-central-1b"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# # Route table association
# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.subnet-1.id
#   route_table_id = aws_route_table.terra-route-table.id
# }

# # Security group
# resource "aws_security_group" "allow_web" {
#   name        = "allow_web_traffic"
#   description = "Allow TLS inbound traffic"
#   vpc_id      = aws_vpc.terra-vpc.id

#   ingress {
#       description      = "HTTPS"
#       from_port        = 443
#       to_port          = 443
#       protocol         = "tcp"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["0.0.0.0/0"]
#     }
#     ingress {
#       description      = "HTTP"
#       from_port        = 80
#       to_port          = 80
#       protocol         = "tcp"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["0.0.0.0/0"]
#     }
#     ingress {
#       description      = "SSH"
#       from_port        = 22
#       to_port          = 22
#       protocol         = "tcp"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["0.0.0.0/0"]
#     }

#   egress {
#       from_port        = 0
#       to_port          = 0
#       protocol         = "-1"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["::/0"]
#     }

#   tags = {
#     Name = "allow_web"
#   }
# }

# # Network interface
# resource "aws_network_interface" "web-server-nic" {
#   subnet_id       = aws_subnet.subnet-1.id
#   private_ips     = ["10.0.0.50"]
#   security_groups = [aws_security_group.allow_web.id]

# #   attachment {
# #     instance     = aws_instance.test.id
# #     device_index = 1
# #   }
# }

# # EIP
# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.web-server-nic.id
#   associate_with_private_ip = "10.0.0.50"
#   depends_on                = [aws_internet_gateway.terra-gateway]
# }

# # Server
# resource "aws_instance" "terraform_instance" {
#   ami           = "ami-047e03b8591f2d48a"
#   instance_type = "t2.micro"
#   availability_zone = "eu-central-1b"
#   key_name = "ec2-mainkey"

#   network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.web-server-nic.id
#   }

#   user_data = <<-EOF
#                 sudo apt update -y
#                 sudo aptinstall apache2 -y
#                 sudo systemctl start apache2
#                 sudo bash -c "echo first webserver > /var/www/html/index.html"
#                 EOF

#   tags = {
#     Name = "terraform_instance"
#   }
# }