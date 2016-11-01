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


# IAM user for reading from the deploy bucket

resource "aws_iam_user" "parsec_instance" {
    name = "parsec-instance-user"
}

resource "aws_iam_access_key" "parsec_instance_user" {
    user = "${aws_iam_user.parsec_instance.name}"
}

resource "aws_iam_user_policy" "parsec_instance_user_perms" {
    # TODO: Restrict to read-only
    name = "parsec-instance-user-policy"
    user = "${aws_iam_user.parsec_instance.name}"
    depends_on = ["aws_s3_bucket.deploybucket"]
    policy= <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.deploybucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.deploybucket.bucket}/*"
            ]
        }
   ]
}
EOF
}


# A few non-standard DLLs we want to send

resource "aws_s3_bucket" "deploybucket" {
  bucket = "parsec-deploy"
  acl    = "private"
}

resource "aws_s3_bucket_object" "xinputdll" {
  bucket   = "${aws_s3_bucket.deploybucket.bucket}"
  key      = "System32/XInput9_1_0.dll"
  source   = "System32/XInput9_1_0.dll"
  etag     = "${md5(file("System32/XInput9_1_0.dll"))}"
}

resource "aws_s3_bucket_object" "vcredist64" {
  bucket   = "${aws_s3_bucket.deploybucket.bucket}"
  key      = "Redist/vcredist_x64.exe"
  source   = "Redist/vcredist_x64.exe"
  etag     = "${md5(file("Redist/vcredist_x64.exe"))}"
}

resource "aws_s3_bucket_object" "vcredist86" {
  bucket   = "${aws_s3_bucket.deploybucket.bucket}"
  key      = "Redist/vcredist_x86.exe"
  source   = "Redist/vcredist_x86.exe"
  etag     = "${md5(file("Redist/vcredist_x86.exe"))}"
}


# Core Formation

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
  description = "Allow inbound Parsec+VNC traffic and all outbound."

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

  ingress {
      from_port = 5900
      to_port = 5901
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
    # TODO: Pass in S3 filekeys as vars (which introduces deps.)
    template = "${file("user_data.tmpl")}"
    vars {
        authcode = "${var.parsec_authcode}"
        deploy_bucket = "${aws_s3_bucket.deploybucket.bucket}"
        iam_key = "${aws_iam_access_key.parsec_instance_user.id}"
        iam_secret = "${aws_iam_access_key.parsec_instance_user.secret}"
        reg_user_root = "HKEY_USERS\\S-1-5-21-2194300291-1390441514-1065349922-500"
        vcredist86_key = "${aws_s3_bucket_object.vcredist86.key}"
        vcredist64_key = "${aws_s3_bucket_object.vcredist64.key}"
        xinputdll_key = "${aws_s3_bucket_object.xinputdll.key}"
    }
}

resource "aws_ebs_volume" "parsec_game_drive" {
    size = 100
    type = "gp2"
    availability_zone = "us-east-1b"
    lifecycle {
      prevent_destroy = true
    }
    tags {
      Name = "ParsecGameDrive"
    }
}

resource "aws_volume_attachment" "game_drive_att" {
    device_name = "xvdg"
    volume_id = "${aws_ebs_volume.parsec_game_drive.id}"
    instance_id = "${aws_instance.parsec.id}"
}

resource "aws_instance" "parsec" {
    # spot_price = "0.7"
    # wait_for_fulfillment = true
    # spot_type = "one-time"
    ami = "${data.aws_ami.parsec.id}"
    instance_type = "g2.2xlarge"
    availability_zone = "us-east-1b"

    tags {
      Name = "ParsecServer"
    }

    root_block_device {
      volume_size = 30
    }

    user_data = "${data.template_file.user_data.rendered}"

    security_groups = ["${aws_security_group.parsec.name}"]
    associate_public_ip_address = true
}
