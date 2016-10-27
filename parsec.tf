# Variables

variable "parsec_authcode" {
  type = "string"
}

variable "aws_access_key" {
  type = "string"
}

variable "aws_secret" {
  type = "string"
}

variable "aws_region" {
  type = "string"
}


# Template

provider "aws" {
  region = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret}"
}

data "aws_ami" "parsec" {
  most_recent = true
  filter {
    name = "name"
    values = ["parsec-ws2012-1"]
  }
}

resource "aws_security_group" "parsec" {
  name = "parsec"
  description = "Allow inbound Parsec traffic and all outbound."

  ingress {
      from_port = 8000
      to_port = 8004
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8000
      to_port = 8004
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8000
      to_port = 8004
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
    template = "${file("user_data.tmpl")}"

    vars {
        authcode = "${var.parsec_authcode}"
    }
}

resource "aws_spot_instance_request" "parsec" {
    spot_price = "0.7"
    ami = "${data.aws_ami.parsec.id}"
    instance_type = "g2.2xlarge"
    spot_type = "one-time"

    tags {
        Name = "ParsecServer"
    }

    root_block_device {
      volume_size = 30
    }

    ebs_block_device {
      volume_size = 100
      volume_type = "gp2"
      device_name = "xvdg"
    }

    user_data = "${data.template_file.user_data.rendered}"

    vpc_security_group_ids = ["${aws_security_group.parsec.id}"]
    associate_public_ip_address = true
}
