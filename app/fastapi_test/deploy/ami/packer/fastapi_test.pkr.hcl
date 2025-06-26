packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "region" {
  default = "us-west-2"
}

variable "ami_name" {
  default = "fastapi-test"
}

variable "app_version" {
  description = "The version of the application"
}

source "amazon-ebs" "fastapi_test" {
  region                  = var.region
  instance_type           = "c5.large"
  ssh_username            = "ubuntu"
  ami_name                = join("-", [var.ami_name, var.app_version, formatdate("YYYYMMDDhhmmss", timestamp())])
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  # Tags that will be applied to the final AMI
  tags = {
    Project     = var.ami_name
    CreatedBy   = "packer"
  }

  # Tags that will be applied to the temporary build EC2 instance
  run_tags = {
    Project     = var.ami_name
    CreatedBy   = "packer"
  }
}

build {
  name    = "fastapi-test"
  sources = ["source.amazon-ebs.fastapi_test"]

  provisioner "shell" {
    inline = [
      "apt remove -y command-not-found",
      "rm -f /etc/apt/apt.conf.d/50command-not-found",
      "apt update",
      "apt install -y git curl"
    ]
    execute_command = "sudo -E bash '{{ .Path }}'"
  }

  # Prep the folder for the FastAPI application
  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/experiments/app"
    ]
  }

  provisioner "file" {
    source      = "../../../../../../experiments/app/fastapi_test"
    destination = "/tmp/experiments/app/fastapi_test"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/experiments/app/fastapi_test/deploy/ami/packer/install.sh",
      "sudo -u ubuntu -i bash /tmp/experiments/app/fastapi_test/deploy/ami/packer/install.sh"
    ]
    environment_vars = ["HOME=/home/ubuntu"]
  }
}
