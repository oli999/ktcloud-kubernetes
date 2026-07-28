
### istioctl 설치

```bash
sudo yum install socat -y
# sudo apt-get install socat -y

# 1. Istio 설치 파일 다운로드 (공식 스크립트를 통해 최신 버전을 다운로드합니다)
curl -L https://istio.io/downloadIstio | sh -

# 2. 다운로드된 폴더로 이동 (명령어를 치면 istio-1.x.x 형태의 폴더로 들어갑니다)
cd istio-*

# 3. istioctl 실행 파일을 전역 경로로 복사 (어디서든 명령어를 칠 수 있게 만듭니다)
sudo cp bin/istioctl /usr/local/bin/

# 4. 정상적으로 설치되었는지 버전 확인 (worker node 에 socat 이 설치 안되어 있으면 에러나는데 상관없음)
# istioctl version

# 5. Istio Ingress Gateway 클러스터에 배포하기
# 쿠버네티스 클러스터에 Istio 기본 구성요소(Gateway 포함)를 쫙 깔아줍니다.
istioctl install --set profile=default -y

# 6. 명령어가 성공적으로 끝나면 kubectl get svc -n istio-system을 쳐서 istio-ingressgateway가 정상적으로 떴는지 확인해 주시면 됩니다.
kubectl get svc -n istio-system
```


Istio는 크게 두 가지를 순서대로 설치해야 합니다.

1. base: Istio의 뼈대(CRD)

2. istiod: 트래픽을 지휘하는 통제실 (Control Plane)

```bash
# 테라폼으로 Istio 설치가 끝났다면, 앞서 말씀드린 "사이드카 자동 주입" 라벨을 앱이 배포될 네임스페이스(예: default)에 반드시 붙여주셔야 합니다.

kubectl label namespace default istio-injection=enabled

#이 라벨이 붙어있어야, 나중에 FastAPI 파드들을 배포할 때 Istio가 몰래 Envoy 프록시(사이드카 컨테이너)를 파드 안에 쏙쏙 끼워 넣어 트래픽을 가로채고 검증할 수 있게 됩니다.
```

사전 준비: Istio 사이드카 주입

```bash
kubectl label namespace default istio-injection=enabled --overwrite
```

최종 실행
```bash
kubectl apply -f msa-apps.yaml
kubectl apply -f msa-routing.yaml
kubectl apply -f msa-security.yaml
```

### Kiali 설치및 접속 

```bash
# 아까 압축을 해제했던 istio-1.x.x 폴더 안으로 이동합니다.
cd ~/kubernetes/example/step11_istio/deploy/istio-*


# 데이터 수집기(Prometheus) 설치
kubectl apply -f samples/addons/prometheus.yaml

# 시각화 대시보드(Kiali) 설치
kubectl apply -f samples/addons/kiali.yaml

# MetalLB를 이용해 외부 접속 열어주기
kubectl patch svc kiali -n istio-system -p '{"spec": {"type": "LoadBalancer"}}'

kubectl get svc kiali -n istio-system
```