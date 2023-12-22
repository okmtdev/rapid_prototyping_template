# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  # CloudFront distribution のオリジンを指定
  origin {
    domain_name = aws_s3_bucket.prototype.bucket_regional_domain_name
    origin_id   = "S3-Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  # CloudFrontの個別設定には有効・無効があるが、すぐ使うので有効に
  enabled = true
  # デフォルトルートにはindex.htmlを指定
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

    # CloudFront Function をアタッチする
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth_function.arn
    }
  }

  # 価格帯を指定する。PriceClass_All, PriceClass_200, PriceClass_100から選べる
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
    Environment = "development"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  # origin access identities を使ってアクセス権限を管理する。
  comment = "OAI for accessing S3 bucket"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function
resource "aws_cloudfront_function" "basic_auth_function" {
  # fuctionの名前
  name    = "basic-auth-function"
  runtime = "cloudfront-js-1.0"

  publish = true

  # Basic認証を行うコードを記述
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
