
```bash
# aws 접근 정보 얻어내기
aws sts get-caller-identity

# 계정 ID를 변수에 저장
export AWS_ID=$(aws sts get-caller-identity --query Account --output text)

# 변수를 써서 ECR 원샷 로그인!
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.ap-northeast-2.amazonaws.com
```

### 1단계: 테라폼으로 ECR '빈 창고(Repository)' 만들기

```bash
# terraform 으로 만들기
resource "aws_ecr_repository" "member-app" {
  name                 = "member-app" # 창고 이름
  image_tag_mutability = "MUTABLE"        # 동일한 태그(v1) 덮어쓰기 허용

  image_scanning_configuration {
    scan_on_push = true                   # 이미지 올릴 때마다 보안 취약점 검사 (필수!)
  }
}

# cli 로 만들기
aws ecr create-repository \
    --repository-name member-app \
    --image-tag-mutability MUTABLE \
    --image-scanning-configuration scanOnPush=true \
    --region ap-northeast-2

# 삭제하기 
aws ecr delete-repository \
    --repository-name member-app \
    --force \
    --region ap-northeast-2

# 테라폼으로 삭제하기 
resource "aws_ecr_repository" "member-app" {
  name         = "member-app"
  force_delete = true   # 🌟 [핵심] 안에 이미지가 있어도 destroy 시 강제 삭제 허용!
}
# 수정하기
# 보안 스캔 기능 끄기 (수정)
aws ecr put-image-scanning-configuration \
    --repository-name member-app \
    --image-scanning-configuration scanOnPush=false \
    --region ap-northeast-2

# 태그 덮어쓰기 금지(IMMUTABLE)로 변경 (수정)
aws ecr put-image-tag-mutability \
    --repository-name member-app \
    --image-tag-mutability IMMUTABLE \
    --region ap-northeast-2
```


### 2단계: ECR에 이미지 올리기 (Local vs GitHub Actions)

```bash
# aws 접속정보 얻어내기
aws sts get-caller-identity

{
    "UserId": "AIDAV2XPFYWZX7FTRCA3F",
    "Account": "401007297971",
    "Arn": "arn:aws:iam::401007297971:user/admin"
}

# 위에서 Account 가 aws 계정 id 이다 

# 1. 계정 ID를 변수에 저장
export AWS_ID=$(aws sts get-caller-identity --query Account --output text)

# 2. AWS ECR에 도커 로그인 (비밀번호를 가져와서 도커에 전달)
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $AWS_ID.dkr.ecr.ap-northeast-2.amazonaws.com

# 2. 로컬에서 만든 이미지에 ECR 주소표표(Tag) 달기
docker tag myoli999/member-app:1.0 $AWS_ID.dkr.ecr.ap-northeast-2.amazonaws.com/member-app:v1.0

# 3. ECR로 밀어넣기 (Push)
docker push $AWS_ID.dkr.ecr.ap-northeast-2.amazonaws.com/member-app:v1.0
```

