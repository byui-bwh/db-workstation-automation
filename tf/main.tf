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

variable "ami_list" {
 description = "This is a list of AMI for DB instances per class"
 type        = list(string)
 default     = ["ami-0cb7f66db0b14b733", "ami-0cb7f66db0b14b733", "ami-09d0b3bf6ce250dd5", "ami-09d0b3bf6ce250dd5"]
}

variable "course_selection" {
 description = "This is the course selection from user input"
 type        = number
 default     = 3
}

resource "aws_key_pair" "db_workstation_key" {
    key_name = "db_workstation"
    public_key = file("/home/cloudshell-user/tf/db_workstation.pub")
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
  ami           = var.ami_list[var.course_selection]
  instance_type = "r6a.large"
  disable_api_termination = true
  iam_instance_profile = "LabInstanceProfile"
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = aws_key_pair.db_workstation_key.key_name
  
  tags = {
    Name = "DB Ubuntu Workstation"
  }
}

