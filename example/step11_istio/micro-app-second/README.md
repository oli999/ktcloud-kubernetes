### 아래의 이미지를 만들어서 docker hub 에 업로드함
- myoli999/micro-index:1.0
- myoli999/micro-user:1.0
- myoli999/micro-market:1.0
- myoli999/micro-posts:1.0

# src 폴더 안에서 아래의 명령어를 실행한다

1. 비대칭키(RS256) 쌍 생성

# 1. 토큰 발급용 비공개키(Private Key) 생성 (유저 서비스 내부에 숨김)
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048

# 2. 토큰 검증용 공개키(Public Key) 추출 (외부 및 이스티오에 노출)
openssl rsa -pubout -in private_key.pem -out public_key.pem