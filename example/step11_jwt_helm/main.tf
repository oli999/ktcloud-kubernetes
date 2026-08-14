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

# 3. Istio Ingress Gateway 설치 (🌟 여기에 ClusterIP 설정 적용)
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  depends_on = [helm_release.istiod]

  # istioctl의 --set components.ingressGateways[0].k8s.service.type=ClusterIP 와 동일한 역할
  set {
    name  = "service.type"
    value = "ClusterIP" # 테스트를 위해 LoadBalancer 해도 된다 
  }
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
# 🌟 수정된 부분: extraScrapeConfigs가 반드시 'server:' 하위에 위치해야 합니다!
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
  # 🌟 수정된 부분: Kiali UI에서 클릭 시 띄워줄 주소 (포트 80 명시)
  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-server.istio-system.svc.cluster.local:80"
  }
  set {
    name  = "deployment.service_type" 
    value = "LoadBalancer"
  }
  # Kiali가 Grafana의 위치를 알 수 있도록 URL 연결
  set {
    name  = "external_services.grafana.in_cluster_url"
    value = "http://grafana.istio-system.svc.cluster.local:80"
  }
  # 🌟 (추가해야 할 부분) Kiali 화면에서 'View in Grafana' 클릭 시 이동할 외부 주소
  # 나중에 실제 운영 시에는 이 url 값에 Grafana의 LoadBalancer 외부 IP나 도메인을 넣어주시면 웹 브라우저에서 곧바로 열리게 됩니다
  set {
    name  = "external_services.grafana.url"
    value = "http://grafana.istio-system.svc.cluster.local:80"
  }
}

# -------------------------------------------------------------------------
# 7. Grafana 설치 (시각화 및 알림 대시보드)
# -------------------------------------------------------------------------
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "istio-system"

  # Prometheus가 먼저 떠 있어야 데이터를 끌어올 수 있음
  depends_on = [helm_release.prometheus]

  # 웹 브라우저 접속을 위한 LoadBalancer 개방
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  # 테스트 환경을 위한 admin 비밀번호 고정 (아이디: admin / 비밀번호: admin)
  set {
    name  = "adminPassword"
    value = "admin"
  }

# 🌟 수정된 부분: 404 에러가 나지 않도록 최신 Istio 깃허브 URL 경로로 업데이트
  # 🌟 더 이상 깨지지 않는 궁극의 방법 (Grafana 공식 마켓플레이스 ID 사용)
  values = [
    <<-EOF
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server.istio-system.svc.cluster.local:80
          access: proxy
          isDefault: true
          
    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
        - name: 'istio'
          orgId: 1
          folder: 'istio'
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/istio
            
    dashboards:
      istio:
        istio-mesh:
          gnetId: 7639
          revision: 158
          datasource: Prometheus
        istio-service:
          gnetId: 7636
          revision: 158
          datasource: Prometheus
        istio-workload:
          gnetId: 7630
          revision: 158
          datasource: Prometheus
    EOF
  ]
}