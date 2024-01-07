terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.6.6"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0fdceeca02bef28ea"
  instance_type = "t3a.large"
  disable_api_termination = true

  tags = {
    Name = "DB Ubuntu Workstation"
  }
}

