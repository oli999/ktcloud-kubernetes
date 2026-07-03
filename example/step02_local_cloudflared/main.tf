# main.tf
terraform {
  required_providers {
    # cloudflare 를 terraform 에서 사용할수 있도록 준비
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# cloudflared 에 로그인해서 아래의 변수에 전달할 정보를 가지고 와서 terraform.tfvars 파일에 미리 기입을 해둔다.
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID (도메인의 고유 ID)"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "domain_name" {
  description = "연결할 외부 도메인 (예: yourdomain.com)"
  type        = string
}

resource "null_resource" "install_cloudflared_pod" {
    # 1. 터널 라우팅 규칙과 DNS 세팅이 "완벽히 끝난 후"에 앤서블을 실행해라!
    depends_on = [
        cloudflare_tunnel_config.vmware_config,
        cloudflare_record.vmware_dns
    ]

    # 2. 터널 토큰이 바뀌면 무조건 앤서블을 다시 실행해라! (항상 실행하려면 timestamp 적용)
    triggers = {
        always_run = "${timestamp()}"
    }

    # aws 에 프로비저닝을 하는것이 아닌 local 에서 직접 ansible 플레이북을 실행 
    provisioner "local-exec" {
        command = "ansible-playbook -i localhost, -c local playbook-kubectl.yml --extra-vars 'tunnel_token=${cloudflare_tunnel.vmware_tunnel.tunnel_token}'"
    }
}

