

### 기존 매니페스트를 먼저 제거

```bash
# 1. 기존 MetalLB 매니페스트 삭제
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

# 2. Terraform 실행
terraform apply

# 3. IP Pool 및 Advertisement 적용 (방법 A 사용 시)
kubectl apply -f 02-ip-pool.yaml
kubectl apply -f 03-advertise.yaml
```