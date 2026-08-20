# main.tf 파일
terraform {
  required_providers {
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


# helm provider 가 동작할 준비가 되어 있으면 "helm_release" 를 사용할수 있다.
resource "helm_release" "argocd" {
  name             = "argocd"
  # helm 저장소의 위치
  repository       = "https://argoproj.github.io/argo-helm"
  # chart 의 이름
  chart            = "argo-cd"
  # chart 버전
  version          = "10.1.2"
  # namespace 설정 
  namespace        = "argocd"
  create_namespace = true
  # my-values.yaml 파일을 읽어서 설치 하도록 한다 
  values = [ file("${path.module}/argocd-values.yaml") ]
  # 초기 비밀번호를 직접 설정하기 
  set {
    name  = "configs.secret.argocdServerAdminPassword"
    # htpasswd (bcrypt) 형태로 변환하여 주입
    value = bcrypt("@admin1234") 
  }
}

# -------------------------------------------------------------------------
# Argo Rollouts 설치
# -------------------------------------------------------------------------
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  namespace        = "argo-rollouts"
  create_namespace = true # 자동으로 argo-rollouts 네임스페이스를 생성합니다.

  # 버전 고정이 필요할 경우 아래 주석을 풀고 사용하세요.
  # version = "2.38.0" 

  # (선택) 웹 대시보드 활성화가 필요하다면 아래 설정을 추가합니다.
  set {
    name  = "dashboard.enabled"
    value = "true"
  }
}