
## terraform helm 기반으로 istio 설치하기

### 기존에 설치된 자원 reset 하기

```bash
kubectl delete ns micro
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

### kiali 접속 정보 확인

<img src="./assets/image.png">


### argo-rollouts 플러그인 설치

```bash
# 1. 최신 플러그인 바이너리 다운로드
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64

# 2. 실행 권한 부여
chmod +x ./kubectl-argo-rollouts-linux-amd64

# 3. 환경 변수 경로로 이동 (kubectl이 인식할 수 있도록)
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

kubectl argo rollouts version

kubectl argo rollouts get rollout rollout-fastapi-user -n micro

kubectl argo rollouts promote rollout-fastapi-user -n micro
```