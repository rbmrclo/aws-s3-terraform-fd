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
