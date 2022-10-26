provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  endpoints {
    s3     = "http://localhost:4566"
    iam    = "http://localhost:4566"
    lambda = "http://localhost:4566"
    ec2        = "http://localhost:4566"
    sts        = "http://localhost:4566"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucketOrigin.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python"
  output_path = "${path.module}/python/index.zip"
}


resource "aws_lambda_function" "func" {
  filename      = "${path.module}/python/index.zip"
  function_name = "example_lambda_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.lambda_handler"
  source_code_hash = "${data.archive_file.zip_the_python_code.output_base64sha256}"
  runtime       = "python3.8"
}

resource "aws_s3_bucket" "bucketOrigin" {
  bucket = "origin"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucketOrigin.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}