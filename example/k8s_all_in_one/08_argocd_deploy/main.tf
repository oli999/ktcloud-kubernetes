# main.tf 파일
terraform {
  required_providers {
    # ArgoCD 전용 프로바이더 선언
    argocd = {
      source  = "oboukili/argocd"
      version = "6.1.1" # 최신 안정화 버전
    }
    # terraform 으로 k8s 자원들을 provision 할수 있도록 provider 추가 
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30" 
    }
    # terraform 으로 helm chart 를 직접 배포 가능하도록 하는 provider 추가
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}
# 클러스터 접속정보 (local k8s 를 바라 보도록 context 가 변경되어 있어야 한다)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# helm provider 가 동작하려면 config 파일 정보를 전달해야 한다. 
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


# 1. K8s 안에서 ArgoCD Service 리소스를 검색해서 가져옴
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server" # 헬름이 생성한 서비스 이름
    namespace = "argocd" # namespace 
  }
}

provider "argocd" {
  # cluster_ip 
  # server_addr = "${data.kubernetes_service.argocd_server.spec[0].cluster_ip}:80" 
  # external_ip
  server_addr = "${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip}:80"

  # 초기 로그인 계정 정보
  username    = "admin"
  password    = "abcd1234" 

  # 우리가 --insecure 로 HTTPS를 껐기 때문에 아래 옵션이 반드시 필요합니다!
  plain_text = true
  insecure   = true 
}

# external_ip 가 잘 얻어내지는지 확인
output "argocd_server_ip" {
  description = "argocd ip"
  value = "${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip}"
}

# 배포할 app 구성하기
resource "argocd_application" "hello_app"{
    # 배포할 app 의 이름과 namespace 를 명시 한다 
    metadata {
      name = "hello-app"
      namespace = "argocd"
    }
    spec {
        project = "default"
        source {
            # gitea
            repo_url = "http://172.16.8.42/admin/argocd_deploy.git"
            # 바라볼 브랜치 (master 또는 main)
            target_revision = "master"
            
            # 핵심: Chart.yaml이 위치한 폴더 경로를 지정합니다.
            path            = "hello"
            
            # (옵션) Helm 특정 설정이 필요할 때
            # helm {
            #     value_files = ["values.yaml"]
            # }
        }
        destination {
            # 정해진 이름 
            server = "https://kubernetes.default.svc"
            namespace = "default" # 배포할 namespace 지정 
        }
        # 동기화 정책
        sync_policy {
            automated {
                prune       = true
                self_heal   = true
            }
            # namespace 가 없는경우 자동으로 만들어 지도록   
            sync_options = ["CreateNamespace=true"]
        }
    }  
}