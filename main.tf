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

  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tags = {
    Name = "Freddy"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"
  name    = "blog_new_freddy"

  vpc_id  = data.aws.vpc.default.id
  ingress_rules =. ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules =. [all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
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