output "website_url" {
  description = "The URL of the static website"
  value       = aws_s3_bucket.resume_site.website_endpoint
}

output "cloudfront_url" {
  description = "The CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.resume_distribution.domain_name}"
}
