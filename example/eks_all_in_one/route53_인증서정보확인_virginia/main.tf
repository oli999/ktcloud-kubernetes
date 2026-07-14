# 1. 버지니아 리전 프로바이더 추가 (테라폼에게 미국 동부 가는 길을 알려줌)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# Route 53 도메인 장부 정보 읽어오기
data "aws_route53_zone" "selected" {
  name = "${var.domain_name}."
  private_zone = false
}

# 미리 만들어서 준비된 인증서 가져오기 
data "aws_acm_certificate" "issued_cert" {
  provider    = aws.virginia
  domain = var.domain_name
  statuses = ["ISSUED"]
  most_recent = true
}

# 테스트용으로 인증서의 arn 출력해 보기
output "certificate_arn" {
  value = data.aws_acm_certificate.issued_cert.arn
}

# variables.tf 에 domain_name 변수 추가 
variable "domain_name" {
  default = "cloud-study.site"
}