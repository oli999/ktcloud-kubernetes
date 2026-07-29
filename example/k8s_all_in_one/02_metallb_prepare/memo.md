
### 기존 metallb clear

```bash
# custom resource definition 삭제 
# xargs = "앞 명령어가 찾아낸 결과물 목록을, 뒤 명령어의 매개변수로 쏙쏙 넘겨서 일괄 처리해 주는 도구"
kubectl get crd -o name | grep metallb | xargs kubectl delete

# metallb namespace 삭제 
kubectl delete namespace metallb-system --ignore-not-found=true

# metallb-webhook-configuration 삭제
kubectl delete ValidatingWebhookConfiguration metallb-webhook-configuration
```