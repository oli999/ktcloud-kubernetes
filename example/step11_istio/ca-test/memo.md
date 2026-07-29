
### nodejs 24 설치

```bash
# nvm 다운로드 및 설치:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

source ~/.bashrc

# Node.js 다운로드 및 설치:
nvm install 24
# Node.js 버전 확인:
node -v # "v24.18.0"가 출력되어야 합니다.
nvm current # "v24.18.0"가 출력되어야 합니다.
# Verify the Node.js version:
node -v # Should print "v24.18.0".
# npm 버전을 확인:
npm -v # 11.16.0가 출력되어야 합니다.
```


### 1단계: 내가 직접 '최상위 인증기관(Root CA)' 되기

```bash
# 1. Root CA의 비밀키(Private Key) 생성
openssl genrsa -out myRootCA.key 2048

# 2. 비밀키를 이용해 Root CA 자체 서명 인증서(PEM) 발급
# (실제 운영 환경의 /usr/share/ca-certificates 안에 있는 공인 인증서들과 같은 역할)
openssl req -x509 -new -nodes -key myRootCA.key -sha256 -days 3650 \
  -out myRootCA.pem \
  -subj "/C=KR/O=My Local Company/CN=My Awesome Root CA"
```

### 2단계: 웹 서버용 인증서 만들고 Root CA로 서명하기

```bash
# 1. 웹 서버용 비밀키 생성
openssl genrsa -out server.key 2048

# 2. 인증서 발급 요청서(CSR) 생성 (도메인은 localhost로 지정)
openssl req -new -key server.key -out server.csr \
  -subj "/C=KR/O=My Local Company/CN=localhost"

# 3. ⭐️ 내 Root CA(myRootCA.pem)를 사용해서 서버 인증서(server.crt) 서명 발급!
openssl x509 -req -in server.csr \
  -CA myRootCA.pem -CAkey myRootCA.key -CAcreateserial \
  -out server.crt -days 825 -sha256
```

### 3단계: Node.js로 초간단 HTTPS 웹 서버 띄우기

```bash
mkdir src
# 1. 간단한 Node.js 웹 서버 코드 작성
cat << 'EOF' > server.js
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.crt')
};

https.createServer(options, (req, res) => {
  res.writeHead(200);
  res.end('나만의 사설 인증서 체인 테스트 성공!!!\n');
}).listen(8443);

console.log('HTTPS 서버가 8443 포트에서 실행 중입니다...');
EOF

# 2. 서버 백그라운드 실행
node server.js &
```

### 4단계: 인증서 체인 검증 테스트 

```bash
# error
curl https://localhost:8443

curl https://localhost:8443 --cacert myRootCA.pem
```

>실제 회사에서 마이크로서비스를 구축하면, User 파드, Market 파드 등 수십 개의 내부 서버들이 서로 통신합니다. 이 내부 서버들끼리 통신할 때마다 비싼 돈 주고 진짜 공인 인증서를 살 수는 없겠죠?
그래서 Istio가 알아서 클러스터 내부에 '우리 회사 전용 가짜 주민센터(Root CA)'를 차립니다. 그리고 모든 파드들에게 사설 신분증을 나눠준 뒤, 파드들끼리 서로 통신할 때 "우리끼리는 이 도장이 찍힌 신분증이면 서로 무조건 믿고 통과시키자(mTLS)!"라고 세팅해 두는 것입니다.
방금 강사님은 Istio가 내부적으로 하는 그 거대한 신분증 발급과 검증 과정을, 내 손으로 직접 컴퓨터 한 대에서 작게 축소해서 경험해 보신 겁니다!