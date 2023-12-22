# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "prototype" {
  # バケット名のプレフィクスに prototype という文字列を指定
  bucket_prefix = "prototype"

  tags = {
    # development タグを付与
    Environment = "development"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  # バケットを指定
  bucket = aws_s3_bucket.prototype.id

  # s3バケットにはCloud Frontからのみアクセスさせるため、各種セキュリティ対策を行う
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# https://registry.terraform.io/providers/hashicorp/aws/3.4.0/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "prototype_policy" {
  # アタッチするバケットを指定
  bucket = aws_s3_bucket.prototype.id

  # アタッチされるポリシーを指定
  policy = data.aws_iam_policy_document.policy_document.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "policy_document" {
  statement {
    # CloudFrontからのアクセスを許可
    sid    = "AllowCloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_oai.iam_arn]
    }
    # Getのみ許可する
    actions = [
      "s3:GetObject"
    ]
    # アクセスを許可するバケットのARNを指定
    resources = [
      "${aws_s3_bucket.prototype.arn}/*"
    ]
  }
}
