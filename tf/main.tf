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

resource "aws_security_group" "sg" {
  name_prefix   = "ssh-dcv-sg"
  description = "Security Group for NICE DCV over HTTPS"
  ingress {
	    from_port   = 8443
	    to_port     = 8443
	    protocol    = "tcp"
	    cidr_blocks = ["0.0.0.0/0"]
	}
	
  ingress {
	    from_port   = 8443
	    to_port     = 8443
	    protocol    = "udp"
	    cidr_blocks = ["0.0.0.0/0"]
	}
  ingress {
	    from_port   = 22
	    to_port     = 22
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

resource "aws_eip" "eip" {
  instance = aws_instance.db_workstation.id
}

resource "aws_instance" "db_workstation" {
  ami           = "ami-0e9aae06cde76e2d9"
  instance_type = "t3a.large"
  disable_api_termination = true
  iam_instance_profile = "LabInstanceProfile"
  vpc_security_group_ids = [aws_security_group.sg.id]
  
  tags = {
    Name = "DB Ubuntu Workstation"
  }
}

