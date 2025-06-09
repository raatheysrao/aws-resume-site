provider "aws" {
  region = "us-east-1"  # Or your preferred region
}

resource "aws_s3_bucket" "resume_site" {
  bucket = var.bucket_name
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "Resume Website"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.resume_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.resume_site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.resume_site.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "resume_oac" {
  name                              = "resume-site-oac"
  description                       = "OAC for Resume S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "resume_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.resume_site.bucket_regional_domain_name
    origin_id   = "S3-resume-site"

    origin_access_control_id = aws_cloudfront_origin_access_control.resume_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-resume-site"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "resume-site-distribution"
    Environment = "Dev"
  }
}
