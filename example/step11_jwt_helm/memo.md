
## terraform helm 기반으로 istio 설치하기

### 기존에 설치된 자원 reset 하기

```bash
kubectl delete ns micro
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

