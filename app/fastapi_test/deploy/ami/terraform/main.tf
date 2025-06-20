
# Reference the remote state of the VPC and subnet module
data "terraform_remote_state" "experiments_apps_network" {
  backend = "s3"  # or use the appropriate backend

  config = {
    bucket = "experiments-infra-state"
    key    = "infra/network_setup/terraform.tfstate"
    region = "us-west-2"
  }
}


# # This Terraform configuration deploys an EC2 instance for a FastAPI application
variable "app_name" {
    description = "The name of the application"
    default     = "fastapi_test"
}

terraform {
  backend "s3" {
    bucket         = "experiments-infra-state"
    key            = "infra/fastapi_test/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"   # Optional for state locking
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}


data "aws_ssm_parameter" "fastapi_test_ami" {
  name = "/ami/fastapi_test/staging"
}

resource "aws_security_group" "fastapi_test_sg" {
  name        = "fastapi-test-sg"
  description = "Allow HTTP, HTTPS and SSH traffic"
  vpc_id      = data.terraform_remote_state.experiments_apps_network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "fastapi_test_instance" {
  for_each        = toset([
      data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_a,
      data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_b
    ])  # Loop over each subnet
  ami             = data.aws_ssm_parameter.fastapi_test_ami.value
  instance_type   = "t3.small"
  key_name        = "investigate_fastapi_test_ec2"
  vpc_security_group_ids = [aws_security_group.fastapi_test_sg.id]
  subnet_id      = each.value

  # Associate the EC2 instance with an IAM role if necessary (for example, if it needs to access S3 or other AWS services)
  # iam_instance_profile = "your-iam-role"

  tags = {
    Project = var.app_name
    Name    = "${var.app_name}-instance in ${each.value}"  # Tag based on subnet ID
    CreatedBy = "terraform"
  }
}


### Setup ALB for the FastAPI application
resource "aws_lb" "fastapi_test_alb" {
  name               = "fastapi-test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fastapi_test_sg.id]
  subnets            = [
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_a,
    data.terraform_remote_state.experiments_apps_network.outputs.subnet_id_b
  ]

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "FastAPI Test App Load Balancer"
  }
}

resource "aws_lb_target_group" "fastapi_test_target_group" {
  name     = "fastapi-test-target-group"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.experiments_apps_network.outputs.vpc_id

  health_check {
    interval            = 30
    path                = "/health"
    port                = "8000"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "FastAPI Test App Target Group"
  }
}

resource "aws_lb_target_group_attachment" "fastapi_test_target_group_attachment" {
  for_each          = aws_instance.fastapi_test_instance  # Loop over EC2 instances
  target_group_arn  = aws_lb_target_group.fastapi_test_target_group.arn
  target_id         = each.value.id  # EC2 instance ID
  port              = 8000
}

resource "aws_lb_listener" "fastapi_test_alb_listener" {
  load_balancer_arn = aws_lb.fastapi_test_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.fastapi_test_target_group.arn
    type             = "forward"
  }
}
