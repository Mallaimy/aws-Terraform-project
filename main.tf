# This terraform config file contains the following architecture.
# 1 VPC
# 2 subnet (Private and public)
# 3 security Group
# 4 EC2 

# provider block
provider "aws" {
   region = "us-east-1"
   profile = "default"
}


# Create a VPC
resource "aws_vpc" "vpc" {

  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.tags}-vpc"
  }
}

# create a public subnets
resource "aws_subnet" "publicSubnet" {
  count = length(var.az)
  vpc_id = aws_vpc.vpc.id
  availability_zone = var.az[count.index]
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.tags}-PublicSubnet-${count.index + 1 }"
  }
}


# create a private subnet 
resource "aws_subnet" "privateSubnet" {
  count = length(var.az)
  vpc_id = aws_vpc.vpc.id
  availability_zone = var.az[count.index]
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index+ length(var.az))
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.tags}-PrivateSubnet-${count.index + 1}"
  }
} 


# create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.tags}-igw"
  }
}

#allocate eip
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.tags}-nat"
  }
}


#Create a Nat gateway
resource "aws_nat_gateway" "ngt" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.publicSubnet[0].id
  depends_on = [aws_internet_gateway.igw]
}


# create public route table
resource "aws_route_table" "publicRouteTable" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  } 
  tags = {
    Name = "${var.tags}-publicRouteTable"
  }
}

# subnet association
resource "aws_route_table_association" "subAssociation" {
  count = length(var.az)
  route_table_id = aws_route_table.publicRouteTable.id
  subnet_id = aws_subnet.publicSubnet[count.index].id
}

# let's create private route table
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngt.id
  }
  tags = {
    Name= "${var.tags}-PrivateRouteTable"
  }
}

# private network association
resource "aws_route_table_association" "PrivateRouteTableAssocistion" {
  count = length(var.az)
  route_table_id = aws_route_table.PrivateRouteTable.id
  subnet_id = aws_subnet.privateSubnet[count.index].id
  
}
# create security groupe
resource "aws_security_group" "elb_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg"
  }
}

resource "aws_security_group" "web_Sg" {
  description = "allow HTTP and SSH traffic"
  name = "web-sg"
  vpc_id = aws_vpc.vpc.id


  # SSH inbound traffic
  ingress  {
    description = " Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP inbound traffic 

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.elb_sg.id]

  }

# allow outbound traffic

  egress {
    description = " Allow every outbound traffic from any port"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tags}-WebSG"
  }
  
}


# Application Load Balancer
resource "aws_lb" "app_lb" {
  name  = "app-lb"
  load_balancer_type = "application"
  subnets = aws_subnet.publicSubnet[*].id
  security_groups = [aws_security_group.elb_sg.id]
  tags = {
    Name = "app load blancer"
  }
}

#Target group
resource "aws_lb_target_group" "app_tg" {
name = "app-tg"
port = 80
protocol = "HTTP"
vpc_id = aws_vpc.vpc.id
target_type = "instance"


health_check {
path = "/"
healthy_threshold = 2
unhealthy_threshold = 2
timeout = 5
interval = 30
matcher = "200"
}
tags = {
  Name = "app Target Groupe"
}
}

# load balancer listner
resource "aws_lb_listener" "http" {
load_balancer_arn = aws_lb.app_lb.arn
port = 80
protocol = "HTTP"

default_action {
type = "forward"
target_group_arn = aws_lb_target_group.app_tg.arn
}

}

# launch Template
resource "aws_launch_template" "app_lt" {
  name_prefix = "app-lt"
  image_id = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  key_name = "MyUbuntu_Key_pair"
  vpc_security_group_ids = [aws_security_group.web_Sg.id]
  user_data = base64encode (<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd mariadb-server
              systemctl enable httpd
              systemctl start httpd
              systemctl enable mariadb
              systemctl start mariadb
              echo "<h1>Good morning welcome back to first ever Cloud Automation I love Cloud Engeneering</h1>" > /var/www/html/index.html
              EOF
              )

  tags = {
    Name = "${var.tags}-Webserver"
  }
  
}

resource "aws_autoscaling_group" "app_ASG" {

  desired_capacity = 2
  max_size = 4
  min_size = 2

  vpc_zone_identifier = aws_subnet.privateSubnet[*].id
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id = aws_launch_template.app_lt.id
    version = "$Latest"
  }

}
