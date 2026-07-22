
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

### jenkins 를 활용한 배포의 구조

<img src="./assets/image04.png">

### timezone 설정

<img src="./assets/image05.png">
<img src="./assets/image06.png">

### groovy 테스트 console 

<img src="./assets/image07.png">

### Harbor, gitea 접속하기 위한 Credentials 등록
<img src="./assets/image08.png"> 
<img src="./assets/image09.png"> 
<img src="./assets/image10.png"> 
<img src="./assets/image11.png"> 
<img src="./assets/image12.png">

### jenkins 플러그인 설치

<img src="./assets/image14.png">
<img src="./assets/image15.png">
<img src="./assets/image16.png">

### gitea 에 있는 Jenkinsfile 을 가져와서 수동으로 실행하는 테스트

<img src="./assets/image17.png">
<img src="./assets/image18.png">
<img src="./assets/image19.png">
<img src="./assets/image20.png">
<img src="./assets/image21.png">
<img src="./assets/image22.png">
<img src="./assets/image23.png">
<img src="./assets/image24.png">
<img src="./assets/image25.png">
<img src="./assets/image26.png">