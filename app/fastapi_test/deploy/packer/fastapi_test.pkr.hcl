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
  default = "fastapi-test-ami"
}

source "amazon-ebs" "fastapi_test" {
  region                  = var.region
  instance_type           = "t3.micro"
  ssh_username            = "ubuntu"
  ami_name                = var.ami_name# + "-" + timestamp(format: "YYYYMMDDHHMMSS")
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                 = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  name    = "fastapi-test"
  sources = ["source.amazon-ebs.fastapi_test"]

  provisioner "shell" {
    inline = [
      "sudo apt remove -y command-not-found",
      "sudo rm -f /etc/apt/apt.conf.d/50command-not-found",
      "sudo apt update",
      "sudo apt install -y git curl"
    ]
  }

  provisioner "file" {
    source      = "../../../../../experiments"
    destination = "/tmp/experiments"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/experiments/app/fastapi_test/deploy/packer/install.sh",
      "bash /tmp/experiments/app/fastapi_test/deploy/packer/install.sh"
    ]
  }
}
