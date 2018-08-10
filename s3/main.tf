provider "aws" {
	region = "eu-central-1"
}

output "bucket_name" {
	value = "${aws_s3_bucket.terraform_state.arn}"
}


resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform-up-and-running-state-00001"
	
	versioning {
		enabled = true
	}

	lifecycle {
		prevent_destroy = true
	}
}

