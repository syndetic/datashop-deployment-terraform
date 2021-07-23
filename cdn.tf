locals {
  frontend_origin_id = "datashop-frontend-origin"
}

resource "aws_cloudfront_distribution" "datashop-frontend" {
  enabled = true

  origin {
    origin_id   = local.frontend_origin_id
    domain_name = var.webapp_domain_name

    custom_origin_config {
      origin_ssl_protocols = ["TLSv1.2"]
      origin_protocol_policy = "https-only"
      http_port = "80"
      https_port = "443"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = "true"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id  = local.frontend_origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
}
