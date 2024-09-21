provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "medusa_instance" {
  ami           = "ami-0522ab6e1ddcc7055"  # Choose an appropriate AMI ID based on your region
  instance_type = "t2.large"
  key_name      = "sathishgurka1"

  tags = {
    Name = "Medusa-Headless"
  }
}

resource "aws_security_group" "new_security_group" {
  name        = "medusa_security_group"
  description = "Allow HTTP, HTTPS, SSH, and Medusa traffic"
  vpc_id      = "vpc-011fe7489b720ff86"  # Replace with your VPC ID
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

resource "aws_security_group_rule" "allow_medusa" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.new_security_group.id
}

