terraform {
  required_providers {
    # AWS プロバイダを使用する
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # 東京リージョンを利用する
  region = "ap-northeast-1"
}
