provider "aws" {
	region = "eu-central-1"
}

variable "http_port" {
	description = "The port the server will use for HTTP requests"
	default = 80
}

output "public_ip" {
	value = "${aws_instance.example.public_ip}"
}


resource "aws_instance" "example" {
	ami = "ami-7c4f7097"
	instance_type = "t2.micro"
	vpc_security_group_ids = ["${aws_security_group.instance.id}"]
	key_name = "frankfurt"

	user_data = <<-EOF
		#!/bin/bash
		yum update -y
		yum install httpd -y
		systemctl start httpd
		systemctl enable httpd
	EOF

	tags {
		Name = "terraform-example"
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

}