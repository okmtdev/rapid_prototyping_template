resource "aws_s3_bucket" "prototype_bucket" {
  bucket_prefix = "prototype-bucket"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.prototype_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  bucket                  = aws_s3_bucket.prototype_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.prototype_bucket.bucket_regional_domain_name
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

        const user = 'username';
        const password = 'password';

        var authString = 'Basic ' + toBase64(user + ':' + password);

        if (typeof headers.authorization == 'undefined' || headers.authorization.value != authString) {
            var response = {
                statusCode: 401,
                statusDescription: 'Unauthorized',
                headers: {
                    'www-authenticate': {value:'Basic'}
                },
            };
            return response;
        }

        return request;
    }
    EOT
}

resource "aws_s3_bucket_policy" "prototype_policy" {
  bucket = aws_s3_bucket.prototype_bucket.id
  policy = data.aws_iam_policy_document.policy_document.json
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid    = "AllowCloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_oai.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.prototype_bucket.arn}/*"
    ]
  }
}
