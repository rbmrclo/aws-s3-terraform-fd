# aws-s3-terraform-fd

In this proof-of-concept, here are the scenarios involved:

- We are using terraform to provision our S3 resources.
- The S3 buckets are used for static website hosting.
- Versioning is not enabled

There are many ways to delete an s3 bucket.
- https://docs.aws.amazon.com/AmazonS3/latest/dev/delete-or-empty-bucket.html

When deleting an S3 bucket, `terraform apply` is expected to raise an error when the bucket is not emptied.
So we will use `force_destroy` option to indicate that all objects should be deleted from the bucket so that the bucket can be destroyed without error.

## Setup

Original logs can be seen here: https://gist.github.com/rbmrclo/2b377a3e3515a048147f1f924fe5162a

```sh
$ git clone git@github.com:rbmrclo/aws-s3-terraform-fd.git

# If you haven't installed terraform on your machine -> https://github.com/tfutils/tfenv
$ brew install tfenv

# To match same version with the one that we use
$ tfenv install 0.10.6

$ cd aws-s3-terraform-fd
$ terraform init
```

## Operation logs

**Goal:** To delete an s3 bucket (non-emptied) without errors.

#### Initial `terraform plan`

```
$ terraform plan

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_s3_bucket.public_website
      id:                       <computed>
      acceleration_status:      <computed>
      acl:                      "private"
      arn:                      <computed>
      bucket:                   "robbie-test-force-destroy"
      bucket_domain_name:       <computed>
      force_destroy:            "false"
      hosted_zone_id:           <computed>
      region:                   <computed>
      request_payer:            <computed>
      versioning.#:             <computed>
      website.#:                "1"
      website.0.error_document: "index.html"
      website.0.index_document: "index.html"
      website_domain:           <computed>
      website_endpoint:         <computed>

  + aws_s3_bucket_policy.public_website
      id:                       <computed>
      bucket:                   "${aws_s3_bucket.public_website.id}"
      policy:                   "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"AddPerm\",\n      \"Effect\": \"Allow\",\n      \"Principal\": \"*\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::robbie-test-force-destroy/*\"\n    }\n  ]\n}\n"


Plan: 2 to add, 0 to change, 0 to destroy.
```

#### Create the s3 bucket

```
$ terraform apply

aws_s3_bucket.public_website: Creating...
  acceleration_status:      "" => "<computed>"
  acl:                      "" => "private"
  arn:                      "" => "<computed>"
  bucket:                   "" => "robbie-test-force-destroy"
  bucket_domain_name:       "" => "<computed>"
  force_destroy:            "" => "false"
  hosted_zone_id:           "" => "<computed>"
  region:                   "" => "<computed>"
  request_payer:            "" => "<computed>"
  versioning.#:             "" => "<computed>"
  website.#:                "" => "1"
  website.0.error_document: "" => "index.html"
  website.0.index_document: "" => "index.html"
  website_domain:           "" => "<computed>"
  website_endpoint:         "" => "<computed>"
aws_s3_bucket.public_website: Still creating... (10s elapsed)
aws_s3_bucket.public_website: Still creating... (20s elapsed)
aws_s3_bucket.public_website: Creation complete after 22s (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Creating...
  bucket: "" => "robbie-test-force-destroy"
  policy: "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"AddPerm\",\n      \"Effect\": \"Allow\",\n      \"Principal\": \"*\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::robbie-test-force-destroy/*\"\n    }\n  ]\n}\n"
aws_s3_bucket_policy.public_website: Creation complete after 2s (ID: robbie-test-force-destroy)

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

#### Upload a file

In this commit
https://github.com/rbmrclo/aws-s3-terraform-fd/commit/e57b79af11f97e0900d68a6f55acf924b1dd2a63,
we've added the test file. We uploaded it manually via AWS console.

```
$ aws s3 ls s3://robbie-test-force-destroy
2019-04-08 13:37:41          4 foo.txt
```

#### Test deletion of bucket via CLI

In this step, we expect the deletion to raise an error. We're doing this for
the sake of gathering facts.

```
$ aws s3 rb s3://robbie-test-force-destroy

remove_bucket failed: s3://robbie-test-force-destroy An error occurred (BucketNotEmpty) when calling the DeleteBucket operation: The bucket you tried to delete is not empty
```

#### Test deletion of bucket via Terraform

It was done in this commit: https://github.com/rbmrclo/aws-s3-terraform-fd/commit/db3c76d77897caf32ddb65def4847fe072848374

```diff
diff --git a/main.tf b/main.tf
index 776b29e..13db9cb 100644
--- a/main.tf
+++ b/main.tf
@@ -10,30 +10,3 @@ provider "aws" {
   max_retries = 3
 }

-resource "aws_s3_bucket" "public_website" {
-  bucket = "robbie-test-force-destroy"
-  acl    = "private"
-  website = {
-    index_document = "index.html"
-    error_document = "index.html"
-  }
-}
-
-resource "aws_s3_bucket_policy" "public_website" {
-  bucket = "${aws_s3_bucket.public_website.id}"
-  policy = <<POLICY
-{
-  "Version": "2012-10-17",
-  "Statement": [
-    {
-      "Sid": "AddPerm",
-      "Effect": "Allow",
-      "Principal": "*",
-      "Action": "s3:GetObject",
-      "Resource": "arn:aws:s3:::robbie-test-force-destroy/*"
-    }
-  ]
-}
-POLICY
-}
-
```

Next, perform `terraform plan` to verify the changes.

```
$ terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

aws_s3_bucket.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Refreshing state... (ID: robbie-test-force-destroy)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - aws_s3_bucket.public_website

  - aws_s3_bucket_policy.public_website


Plan: 0 to add, 0 to change, 2 to destroy.
```

Lastly, run `terraform apply`.

```
$ terraform apply
aws_s3_bucket.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Destroying... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Destruction complete after 1s
aws_s3_bucket.public_website: Destroying... (ID: robbie-test-force-destroy)
Error applying plan:

1 error(s) occurred:

* aws_s3_bucket.public_website (destroy): 1 error(s) occurred:

* aws_s3_bucket.public_website: Error deleting S3 Bucket: BucketNotEmpty: The bucket you tried to delete is not empty
	status code: 409, request id: A036944974BC475B, host id: YGLDvqpbMhEBcKeNLN+HLnYm1SHW0M2vvMom8B1Q+KgfzrzjKm1Vq34uEKYjJW1SgY2P+7iHg1s= "robbie-test-force-destroy"
```

The output above is the expected result. Since the s3 resource that we created
doesn't have `force_destroy` option, running `terraform apply` should raise an
error when attempting to delete the s3 bucket.

#### Now we add `force_destroy`

It was done in this commit: https://github.com/rbmrclo/aws-s3-terraform-fd/commit/39c346535ccf066528b2b8bc00c9e0c4d60a4d38

```diff
diff --git a/main.tf b/main.tf
index 776b29e..dc610c8 100644
--- a/main.tf
+++ b/main.tf
@@ -13,6 +13,7 @@ provider "aws" {
 resource "aws_s3_bucket" "public_website" {
   bucket = "robbie-test-force-destroy"
   acl    = "private"
+  force_destroy = true
   website = {
     index_document = "index.html"
     error_document = "index.html"
```

#### Run `terraform apply` so the s3 bucket will be modified.

In this case, we didn't run `terraform plan` anymore since we already aware of
the expected changes. (although it's greatly encouraged to run `terraform plan`
first before running `terraform apply` all the time.)

```
$ terraform apply

aws_s3_bucket.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket.public_website: Modifying... (ID: robbie-test-force-destroy)
  force_destroy: "false" => "true"
aws_s3_bucket.public_website: Still modifying... (ID: robbie-test-force-destroy, 10s elapsed)
aws_s3_bucket.public_website: Still modifying... (ID: robbie-test-force-destroy, 20s elapsed)
aws_s3_bucket.public_website: Modifications complete after 25s (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Creating...
  bucket: "" => "robbie-test-force-destroy"
  policy: "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"AddPerm\",\n      \"Effect\": \"Allow\",\n      \"Principal\": \"*\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::robbie-test-force-destroy/*\"\n    }\n  ]\n}\n"
aws_s3_bucket_policy.public_website: Creation complete after 1s (ID: robbie-test-force-destroy)

Apply complete! Resources: 1 added, 1 changed, 0 destroyed.
```


#### Next, we delete the s3 resource again

It was done in this commit: https://github.com/rbmrclo/aws-s3-terraform-fd/commit/e7fbb4eca1f17a410ee34798d130a29e6656cb9e

```diff
diff --git a/main.tf b/main.tf
index 776b29e..32669b0 100644
--- a/main.tf
+++ b/main.tf
@@ -9,31 +9,3 @@ provider "aws" {
   secret_key = "${var.secret_key}"
   max_retries = 3
 }
-
-resource "aws_s3_bucket" "public_website" {
-  bucket = "robbie-test-force-destroy"
-  acl    = "private"
-  force_destroy = true
-  website = {
-    index_document = "index.html"
-    error_document = "index.html"
-  }
-}
-
-resource "aws_s3_bucket_policy" "public_website" {
-  bucket = "${aws_s3_bucket.public_website.id}"
-  policy = <<POLICY
-{
-  "Version": "2012-10-17",
-  "Statement": [
-    {
-      "Sid": "AddPerm",
-      "Effect": "Allow",
-      "Principal": "*",
-      "Action": "s3:GetObject",
-      "Resource": "arn:aws:s3:::robbie-test-force-destroy/*"
-    }
-  ]
-}
-POLICY
-}
```

#### Finally, run `terraform apply` to destroy the resource

```
$ terraform apply
aws_s3_bucket.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Refreshing state... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Destroying... (ID: robbie-test-force-destroy)
aws_s3_bucket_policy.public_website: Destruction complete after 2s
aws_s3_bucket.public_website: Destroying... (ID: robbie-test-force-destroy)
aws_s3_bucket.public_website: Destruction complete after 6s

Apply complete! Resources: 0 added, 0 changed, 2 destroyed.
```

Success :rocket: