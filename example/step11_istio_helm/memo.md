
```bash
kubectl label namespace micro istio-injection-
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```