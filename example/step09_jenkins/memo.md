
### jenkins 설치 및 활용

```bash

# 1.Jenkins 공식 헬름 저장소 추가 및 업데이트
helm repo add jenkins https://charts.jenkins.io
helm repo update

# 2. namespace 생성
kubectl create namespace jenkins

# 3. jenkins helm 설치
helm install my-jenkins jenkins/jenkins -f jenkins-values.yaml -n jenkins

```

### helloworld 액션 테스트

<img src="./assets/image01.png">
<img src="./assets/image02.png">
<img src="./assets/image03.png">