provider "aws" {
  region = "us-east-1"
}

variable "TF_ENV" {
  type = "string"
}


resource "aws_s3_bucket" "bucket" {
  acl = "private"
}

resource "aws_iam_role" "firehose_role" {
   name = "${var.TF_ENV}-fh"
   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal":{
      "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}      
EOF
}


resource "aws_iam_role_policy" "firehose_policy" {
  name  = "${var.TF_ENV}-firehose-pl"
  role  = "${aws_iam_role.firehose_role.id}"

  policy = <<EOF
{
    "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:AbortMultipartUpload",
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:ListBucket",
              "s3:ListBucketMultipartUploads",
              "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
              "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
          ]
      }
    ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name = "${var.TF_ENV}"
  destination = "s3"
  s3_configuration {
    role_arn = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.bucket.arn}"
    buffer_size = 3
    buffer_interval = 60
  }
}
