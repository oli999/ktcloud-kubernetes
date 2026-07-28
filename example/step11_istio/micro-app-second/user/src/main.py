# fastapi-user / src/main.py
from fastapi import FastAPI, Body
from datetime import datetime, timedelta, timezone
import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

app = FastAPI()

#  [1] 미리 생성한 비공개키(private_key.pem) 로드
# 실제 운영 환경에서는 파일로 읽거나 Secret 환경 변수로 관리합니다.
with open("private_key.pem", "rb") as key_file:
    private_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None
    )

#  [2] 검증용 공개키(public_key.pem) 로드 및 JWKS 규격 변환 준비
with open("public_key.pem", "rb") as key_file:
    public_key = serialization.load_pem_public_key(key_file.read())

# 공개키의 수학적 인자(n, e)를 추출하여 JWKS 포맷 정의
public_numbers = public_key.public_numbers()
n_int = public_numbers.n
e_int = public_numbers.e

# 고유한 키 ID(kid) 정의 (이스티오가 토큰 헤더의 kid와 대조할 때 사용)
KEY_ID = "k8s-prime-key-id"

# 숫자를 Base64 URL-Safe 인코딩하는 표준 함수
def int_to_base64url(val: int) -> str:
    # 정수를 바이트로 변환 후 base64 인코딩
    import base64
    bytes_len = (val.bit_length() + 7) // 8
    val_bytes = val.to_bytes(bytes_len, byteorder='big')
    return base64.urlsafe_b64encode(val_bytes).decode('utf-8').rstrip('=')

#  [핵심 엔드포인트] 이스티오가 조지식하게 읽어갈 공개키 정보 노출
@app.get("/user/.well-known/jwks.json")
def get_jwks():
    return {
        "keys": [
            {
                "kty": "RSA",
                "alg": "RS256",
                "use": "sig",
                "kid": KEY_ID,
                "n": int_to_base64url(n_int),
                "e": int_to_base64url(e_int)
            }
        ]
    }

# fastapi-user / src/main.py 내부의 로그인 처리 구역 교정
@app.post("/user/login")
def generate_user_token(data: dict = Body(...)):
    username = data.get("userName", "Unknown")
    # 🌟 수강생들 실습 시 가끔 PC 시간이 안 맞아 만료로 튕기는 억까를 방지하기 위해 
    # 토큰 유효기간을 넉넉히 24시간으로 늘려 안정성을 확보합니다.
    expire = datetime.now(timezone.utc) + timedelta(hours=24) 
    
    payload = {
        "sub": username,
        "exp": int(expire.timestamp()),
        # 🌟 현재 가장 안정적으로 작동하는 내부 사설 도메인 규격으로 고정합니다.
        "iss": "http://svc-fastapi-user:8000/user/login", 
        "role": "수강생"
    }
    
    # 🚨 [초특급 중요] 모든 인자를 명시적 키워드로 선언하여 headers가 누락되는 버그를 완벽히 차단합니다.
    token = jwt.encode(
        payload=payload, 
        key=private_key, 
        algorithm="RS256", 
        headers={"kid": KEY_ID} # ◄── 이제 토큰 머리에 'k8s-prime-key-id' 명찰이 확실히 박힙니다!
    )
    
    return {
        "status": "200 OK",
        "access_token": token,
        "token_type": "bearer"
    }