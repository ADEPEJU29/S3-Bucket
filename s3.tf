provider "aws" {
  region  = "us-east-1"  # Set your preferred AWS region
  profile = "default"    # Use the specified AWS CLI profile
}

# S3 Bucket for hosting the React app
resource "aws_s3_bucket" "react_app_bucket" {
  bucket = "adepeju-bucket"  # Replace with your desired bucket name
}

# Public Access Block configuration for the bucket
resource "aws_s3_bucket_public_access_block" "react_app_public_access_block" {
  bucket                  = aws_s3_bucket.react_app_bucket.bucket
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "react_app_website" {
  bucket = aws_s3_bucket.react_app_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy to allow public read access
resource "aws_s3_bucket_policy" "react_app_bucket_policy" {
  bucket = aws_s3_bucket.react_app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app_bucket.arn}/*"
      }
    ]
  })
}

# Use the new aws_s3_object resource for uploading files
resource "aws_s3_object" "react_app_files" {
  for_each = fileset("build", "**/*")  # Assumes build files are located in the "build" directory

  bucket = aws_s3_bucket.react_app_bucket.bucket
  key    = each.value                   # S3 object key (file path in bucket)
  source = "build/${each.value}"        # Local file path
  etag   = filemd5("build/${each.value}") # Ensures files are only uploaded if modified
}

# Output the website URL using the aws_s3_bucket_website_configuration resource
output "website_url" {
  value = aws_s3_bucket_website_configuration.react_app_website.website_endpoint
}
