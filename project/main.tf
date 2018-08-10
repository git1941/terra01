provider "aws" {
	region = "eu-central-1"
}

variable "http_port" {
	description = "The port the server will use for HTTP requests"
	default = 80
}


output "elb_dns_name" {
	value = "${aws_elb.example.dns_name}"
}

#backend make sure to change bucket name 
terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-00001"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

data "aws_availability_zones" "all" {}


resource "aws_launch_configuration" "example" {
	image_id = "ami-7c4f7097"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.instance.id}"]
	key_name = "frankfurt"

	user_data = <<-EOF
		#!/bin/bash
		yum update -y
		yum install httpd -y
		systemctl start httpd
		systemctl enable httpd
		echo "Hello World" > /var/www/html/index.html
	EOF


	lifecycle {
		create_before_destroy = true
	}

	
}

resource "aws_autoscaling_group" "example" {
	launch_configuration = "${aws_launch_configuration.example.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	
	load_balancers = ["${aws_elb.example.name}"]
	health_check_type = "ELB"

	min_size = 2
	max_size = 10
	
	tag {
		key = "Name"
		value = "terraform-asg-example"
		propagate_at_launch = true
	}
}

resource "aws_elb" "example" {
	name = "terraform-asg-example"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	security_groups = ["${aws_security_group.elb.id}"]

	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = "${var.http_port}" 
		instance_protocol = "http"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		interval = 30
		timeout = 3
		target = "HTTP:${var.http_port}/"
	}
}

resource "aws_security_group" "elb" {
	name = "terraform-example-elb"
	
	ingress {
		from_port = "${var.http_port}" 
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0 
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]      
	}

}

resource "aws_security_group" "instance" {
	name = "terraform-example-instance"
	
	ingress {
		from_port = "${var.http_port}" 
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22 
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 80 
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]      
	}

	lifecycle {
		create_before_destroy = true
	}


}