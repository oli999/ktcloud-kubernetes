terraform {
  required_version = ">= 1.10" 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

variable "app_names" {
  description = "ECR에 생성할 애플리케이션(이미지) 이름 목록"
  type        = list(string)
  default     = ["fortune", "greet"] # 아무 값도 안 넣었을 때의 기본값
}


# 앱 목록을 리스트로 정의하여 한 번에 여러 개의 ECR 창고 생성
resource "aws_ecr_repository" "my_apps" {
  for_each = toset(var.app_names)

  # 결과: my-ecr-fortune, my-ecr-greet, my-ecr-member-app 3개의 레포지토리 생성
  name                 = "my-ecr-${each.key}" 
  image_tag_mutability = "MUTABLE"
  # 디버깅시에는 쉽게 지울수 있도록 
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR 수명 주기 정책 (Lifecycle Policy) - 반복문 적용
resource "aws_ecr_lifecycle_policy" "app_cleanup_policies" {
  # 1. 앞에서 생성한 'my_apps' 리소스 모음을 그대로 넘겨받아 반복문을 돕니다.
  for_each = aws_ecr_repository.my_apps

  # 2. each.value.name을 통해 현재 순회 중인 창고의 이름을 가져와 매핑합니다.
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1 # 숫자가 작을수록 먼저 실행됨
        description  = "최근 10개의 이미지만 남기고 모두 삭제 (비용 절감)"
        selection = {
          tagStatus   = "any"                  # 태그가 있든 없든 모든 이미지 대상
          countType   = "imageCountMoreThan"   # 기준: 이미지 개수가 다음 숫자보다 많을 때
          countNumber = 10                     # 남길 개수: 10개
        }
        action = {
          type = "expire"                      # 액션: 폐기(삭제)
        }
      }
    ]
  })
}

# ECR 레포지토리 URL 출력
output "ecr_repository_urls" {
  description = "생성된 각 애플리케이션별 ECR 레포지토리 URL"
  # aws_ecr_repository.my_apps 안의 데이터를 순회하며 "앱이름" = "ECR주소" 형태로 매핑
  value = {
    for app_name, repo in aws_ecr_repository.my_apps : app_name => repo.repository_url
  }
}

# resource "aws_ecr_repository" "member-app" {
#   name                 = "member-app" # 창고 이름
#   image_tag_mutability = "MUTABLE"        # 동일한 태그(v1) 덮어쓰기 허용

#   image_scanning_configuration {
#     scan_on_push = true                   # 이미지 올릴 때마다 보안 취약점 검사 (필수!)
#   }
# }

# # ECR 수명 주기 정책 (Lifecycle Policy)
# resource "aws_ecr_lifecycle_policy" "member_app_cleanup" {
#   # 어떤 창고에 적용할지 이름 지정 (위에서 만든 ECR 이름 참조)
#   repository = aws_ecr_repository.member-app.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1 # 숫자가 작을수록 먼저 실행됨
#         description  = "최근 10개의 이미지만 남기고 모두 삭제 (비용 절감)"
#         selection = {
#           tagStatus   = "any"                  # 태그가 있든 없든 모든 이미지 대상
#           countType   = "imageCountMoreThan"   # 기준: 이미지 개수가 다음 숫자보다 많을 때
#           countNumber = 10                     # 남길 개수: 10개
#         }
#         action = {
#           type = "expire"                      # 액션: 폐기(삭제)
#         }
#       }
#     ]
#   })
# }