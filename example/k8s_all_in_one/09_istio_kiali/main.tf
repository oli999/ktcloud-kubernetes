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

# 1. Istio Base 설치 (CRD 등)
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
}

# 2. Istiod 설치 (컨트롤 플레인)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  depends_on = [helm_release.istio_base]
}

# 3. Istio Ingress Gateway 설치 
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  depends_on = [helm_release.istiod]

  # istio-values.yaml 파일이 적용되도록 한다 (LoadBalancer type 으로 만들어지도록)
  values = [
    file("${path.module}/istio-values.yaml")
  ]
}

# 4. micro 네임스페이스 생성 및 Istio 사이드카 자동 주입 설정
resource "kubernetes_namespace" "micro" {
  metadata {
    name = "micro"
    
    # kubectl label namespace micro istio-injection=enabled 와 동일한 역할
    labels = {
      istio-injection = "enabled"
    }
  }
  
  # Istio 컨트롤 플레인이 완전히 뜬 다음에 네임스페이스를 생성/설정하도록 의존성 부여
  depends_on = [helm_release.istiod]
}

# -------------------------------------------------------------------------
# 5. Prometheus 설치 (Kiali의 눈과 귀 역할 - 메트릭 수집)
# -------------------------------------------------------------------------
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "istio-system" # Kiali와 동일한 네임스페이스 사용

  depends_on = [helm_release.istiod]

  # (선택) 로컬 테스트 환경이므로 디스크 볼륨(PV)을 사용하지 않도록 가볍게 설정
  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }
# extraScrapeConfigs가 반드시 'server:' 하위에 위치해야 합니다!
  values = [
    <<-EOF
    server:
      extraScrapeConfigs: |
        - job_name: 'istiod'
          kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
              - istio-system
          relabel_configs:
          - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            action: keep
            regex: istiod;http-monitoring
    EOF
  ]
}

# -------------------------------------------------------------------------
# 6. Kiali 설치 (Istio 시각화 대시보드)
# -------------------------------------------------------------------------
resource "helm_release" "kiali" {
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  namespace  = "istio-system"
  
  # Istio 컨트롤 플레인과 Prometheus가 모두 뜬 이후에 설치되도록 의존성 부여
  depends_on = [helm_release.istiod, helm_release.prometheus]

  # [중요] 로컬 테스트 환경에서 귀찮은 토큰 로그인 창을 안 띄우고 바로 접속(anonymous)
  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  # Kiali가 데이터를 가져올 Prometheus의 내부 DNS 주소 연결
  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-server.istio-system.svc.cluster.local:80"
  }
  set {
    name  = "deployment.service_type" 
    value = "LoadBalancer"
  }
}
