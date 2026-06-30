data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.blog.id]

  tags = {
    Name = "Freddy"
  }
}

resource "aws_security_group" "blog" {
  name        = "blog"
  descripcion = "Allow http and https in. Allow everything out"

  vpc_id      = data.aws.vpc.default.id  
}

resource "aws_security_group_rule" "blog_http_in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cldr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cldr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}


resource "aws_security_group_rule" "blog_http_out" {
  type        = "engress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cldr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}