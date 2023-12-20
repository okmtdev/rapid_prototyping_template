resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.prototype.bucket_regional_domain_name
    origin_id   = "S3-Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400


    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth_function.arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for accessing S3 bucket"
}

resource "aws_cloudfront_function" "basic_auth_function" {
  name    = "basic-auth-function"
  runtime = "cloudfront-js-1.0"

  publish = true

  code = <<-EOT
    function handler(event) {
    var request = event.request;
    var headers = request.headers;

    // echo -n user:password | base64
    var authString = "Basic dXNlcjpwYXNzd29yZA==";

    if (
      typeof headers.authorization === "undefined" ||
      headers.authorization.value !== authString
    ) {
      return {
        statusCode: 401,
        statusDescription: "Unauthorized",
        headers: { "www-authenticate": { value: "Basic" } }
      };
    }

    return request;
  }
  EOT
}
