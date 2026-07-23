# argocd/main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30" 
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
 
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
  values = [ file("${path.module}/helm-values.yaml") ]
  # 초기 비밀번호를 직접 설정하기 
  set {
    name  = "configs.secret.argocdServerAdminPassword"
    # htpasswd (bcrypt) 형태로 변환하여 주입
    value = bcrypt("admin1234") 
  }
}
