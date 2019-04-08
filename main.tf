terraform {
  required_version = "0.10.6"
}

provider "aws" {
  version = "~> 1.9.0"
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  max_retries = 3
}

resource "aws_s3_bucket" "public_website" {
  bucket = "robbie-test-force-destroy"
  acl    = "private"
  website = {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public_website" {
  bucket = "${aws_s3_bucket.public_website.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AddPerm",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::robbie-test-force-destroy/*"
    }
  ]
}
POLICY
}

