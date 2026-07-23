
1. EKS 클러스터의 OIDC(OpenID Connect) 정보를 이용해, 오직 젠킨스 네임스페이스의 특정 ServiceAccount만 이 역할을 맡을 수 있도록 신뢰 정책(Trust Policy)을 구성합니다. 기존 테라폼 코드에 main.tf 내용을 추가해 주세요.

2. Jenkins ServiceAccount 어노테이션 추가 (Helm values.yaml)

```yaml
serviceAccount:
  create: true
  name: "jenkins-sa" # 테라폼 Condition에 적은 이름과 동일해야 함
  annotations:
    # 🚨 방금 테라폼에서 출력된 Role ARN을 여기에 붙여넣습니다.
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/jenkins-ecr-irsa-role"
```

3. helm upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins

🎉 설정 완료 후의 변화
이제 Jenkins 파이프라인(Jenkinsfile)에서 ECR로 docker push를 할 때, 아까처럼 젠킨스 웹 UI(Credentials)에 등록했던 aws-cred를 불러오는 withCredentials 블록을 아예 통째로 지워버려도 푸시가 기가 막히게 성공합니다.