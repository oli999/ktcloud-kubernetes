# main.tf
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

# 클러스터 접속정보 (eks 를 바라 보도록 context 가 변경되어 있어야 한다)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# helm provider 가 동작하려면 config 파일 정보를 전달해야 한다. 
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# main.tf
resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  
  # 원하시는 버전(예: 0.13.10 또는 최신 버전에 해당하는 차트 버전) 지정
  # version          = "0.13.10"

  namespace        = "metallb-system"
  create_namespace = true

}

# IPAddressPool 생성
resource "kubernetes_manifest" "metallb_ip_pool" {
  depends_on = [helm_release.metallb]

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "ip-pool"
      namespace = "metallb-system"
    }
    spec = {
      addresses = [
        "172.16.8.30-172.16.8.50"
      ]
    }
  }
}

# L2Advertisement 생성
resource "kubernetes_manifest" "metallb_l2_advertisement" {
  depends_on = [kubernetes_manifest.metallb_ip_pool]

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "advertise"
      namespace = "metallb-system"
    }
    spec = {
      ipAddressPools = [
        "ip-pool"
      ]
    }
  }
}