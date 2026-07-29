# 0. 변수 선언 (새로 추가)
variable "jenkins_api_token" {
  description = "Jenkins API 토큰"
  type        = string
  sensitive   = true # 화면이나 로그에 노출되지 않도록 암호화 처리
}

terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "~> 0.10.0"
    }
  }
}

# 1. Jenkins 접속 정보 설정
provider "jenkins" {
  server_url = "https://jenkins.cloud-learning.site"
  username   = "admin"
  password   = var.jenkins_api_token #  변수 참조
}

# 2. 파이프라인 Job 생성
resource "jenkins_job" "msa_pipeline" {
  name     = "msa-backend-pipeline"
  template = file("${path.module}/config.xml")
}

# 3. 파이프라인 생성 직후 1회 자동 실행
resource "null_resource" "trigger_build" {
  depends_on = [jenkins_job.msa_pipeline]

  triggers = {
    job_id = jenkins_job.msa_pipeline.id
  }

  provisioner "local-exec" {
    # curl 명령어 내부에 ${var.변수명} 형태로 보간(Interpolation) 적용
    command = <<-EOT
      curl -X POST "https://jenkins.cloud-learning.site/job/msa-backend-pipeline/build" \
           --user "admin:${var.jenkins_api_token}"
    EOT
  }
}