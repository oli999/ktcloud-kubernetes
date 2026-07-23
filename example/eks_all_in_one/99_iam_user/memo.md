

💡 Secret Key 확인 팁
위 코드에서 sensitive = true로 설정했기 때문에 terraform apply를 해도 터미널 화면에 비밀키가 바로 보이지 않습니다. 키 값을 확인하려면 터미널에 아래 명령어를 입력하시면 됩니다.
terraform output -raw jenkins_ecr_secret_access_key

이렇게 생성된 안전한 Access Key와 Secret Key를 Jenkins의 aws-cred 설정(첨부해주신 이미지의 1단계 부분)에 업데이트해 주시면, 만에 하나 키가 털리더라도 해커는 ECR 이미지 조회 외에는 아무것도 할 수 없는 안전한 환경이 됩니다.