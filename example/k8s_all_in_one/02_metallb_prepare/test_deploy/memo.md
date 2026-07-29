
### metallb 가 잘 동작하는지 테스트

```bash
# 배포
kubectl apply -f deploy.yaml
# nginx-test-lb 서비스에 ip 주소가 할당되는지 확인한다  
kubectl get svc 
# 할당된 ip 주소에 요청을 해본다 http://할당된ip주소
```