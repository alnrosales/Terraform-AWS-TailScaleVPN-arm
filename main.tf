resource "aws_vpc" "tf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name = "TailscaleLab"
  }
}

resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_igw"
  }
}

resource "aws_route_table" "tf_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }

  tags = {
    Name = "tf_route_table"
  }
}

resource "aws_subnet" "tf_subnet-1" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-1a"

  tags = {
    Name = "tf_pubsub-1"
  }
}

resource "aws_subnet" "tf_subnet-2" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.128.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-1b"

  tags = {
    Name = "tf_pubsub-2"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf_subnet-1.id
  route_table_id = aws_route_table.tf_route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.tf_subnet-2.id
  route_table_id = aws_route_table.tf_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "ssh to main-server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["124.217.96.0/21"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#VPN1
resource "aws_launch_template" "vpn1" {
  name                                 = "vpn1"
  image_id                             = data.aws_ami.server_ami.id
  instance_type                        = var.instance_type1
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = var.key_code

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price          = var.price1
      spot_instance_type = "one-time"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.tf_subnet-1.id
    security_groups             = [aws_security_group.allow_ssh.id]
  }

  iam_instance_profile {
    name = var.instance_profile
  }

  placement {
    availability_zone = "us-west-1a"
  }

  user_data = var.userVPN1

}

resource "aws_autoscaling_group" "vpn1" {
  name               = "vpn1"
  availability_zones = ["us-west-1a"]
  max_size           = 2
  min_size           = 1
  desired_capacity   = 1

  launch_template {
    id      = aws_launch_template.vpn1.id
    version = "$Latest"
  }
}

# VPN2
resource "aws_launch_template" "vpn2" {
  name                                 = "vpn2"
  image_id                             = data.aws_ami.server_ami.id
  instance_type                        = var.instance_type2
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = var.key_code

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price          = var.price2
      spot_instance_type = "one-time"
    }
  }

  iam_instance_profile {
    name = var.instance_profile
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.tf_subnet-2.id
    security_groups             = [aws_security_group.allow_ssh.id]
  }

  placement {
    availability_zone = "us-west-1b"
  }

  user_data = var.userVPN2

}

resource "aws_autoscaling_group" "vpn2" {
  name               = "vpn2"
  availability_zones = ["us-west-1b"]
  max_size           = 2
  min_size           = 1
  desired_capacity   = 1

  launch_template {
    id      = aws_launch_template.vpn2.id
    version = "$Latest"
  }
}


