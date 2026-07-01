data "aws_ami" "app_ami" {
  most_recent = true
  

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  owners = [var.ami_filter.owner]
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["${var.environment.network_prefix}.1.0/24", "${var.environment.network_prefix}.2.0/24", "${var.environment.network_prefix}.3.0/24"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]
  
  enable_nat_gateway = true
  
  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"   # was 6.0.0

  vpc_id      = module.blog_vpc.vpc_id
  name        = "${var.environment.name}-blog"
  description = "Allow http and https in, all out"

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

resource "aws_security_group" "blog" {
  name        = "blog"
  description = "Allow http and https in. Allow everything out"

  vpc_id      = module.blog_vpc.vpc_id  
}

resource "aws_security_group_rule" "blog_http_in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_https_in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}


resource "aws_security_group_rule" "blog_http_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id
}

module "blog_alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.environment.name}-blog-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets

  security_groups = [module.blog_sg.security_group_id]

  listeners = {
    blog-https = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_arn = aws_lb_target_group.blog.arn
      }
    }
  }

  tags = {
    Environment = var.environment.name
  }
}

resource "aws_lb_target_group" "blog" {
  name     = "${var.environment.name}-blog"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.blog_vpc.vpc_id
}

module "blog_autoscalling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.2"

  name = "blog"

  min_size = var.min_size
  max_size = var.max_size

  vpc_zone_identifier = module.blog_vpc.public_subnets

  launch_template_name = "${var.environment.name}-blog"
  security_groups = [module.blog_sg.security_group_id]

  instance_type = var.instance_type
  image_id      = data.aws_ami.app_ami.id

  traffic_source_attachments = {
    "${var.environment.name}-blog-alb" = {
      traffic_source_identifier = aws_lb_target_group.blog.arn
    }
  }
}