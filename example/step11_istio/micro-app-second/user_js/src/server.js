const express = require('express');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// ---------------------------------------------------------
// [1] 미리 생성한 키 파일 로드
// ---------------------------------------------------------
const privateKey = fs.readFileSync('private_key.pem', 'utf8');
const publicKeyPem = fs.readFileSync('public_key.pem', 'utf8');

// ---------------------------------------------------------
// [2] 검증용 공개키 JWKS 규격 변환 및 객체 캐싱 (최적화)
// ---------------------------------------------------------
const publicKeyObj = crypto.createPublicKey(publicKeyPem);
const jwk = publicKeyObj.export({ format: 'jwk' });
const KEY_ID = "k8s-prime-key-id";

// 🌟 매 요청마다 생성하지 않도록 바깥에서 미리 완성된 응답 객체를 만들어 둡니다.
const cachedJwksResponse = {
    keys: [
        {
            kty: "RSA",
            alg: "RS256",
            use: "sig",
            kid: KEY_ID,
            n: jwk.n,
            e: jwk.e
        }
    ]
};

// ---------------------------------------------------------
// [핵심 엔드포인트] JWKS 노출 (성능 향상)
// ---------------------------------------------------------
app.get('/user/.well-known/jwks.json', (req, res) => {
    // 🌟 이미 만들어진 객체를 즉시 반환하므로 CPU 낭비가 전혀 없습니다.
    res.json(cachedJwksResponse);
});

// ---------------------------------------------------------
// 로그인 처리 구역 (안정성 향상)
// ---------------------------------------------------------
app.post('/user/login', (req, res) => {
    try {
        const username = req.body.userName || "Unknown";
        
        const payload = {
            sub: username,
            iss: "http://svc-fastapi-user:8000/user/login", 
            role: "수강생"
        };

        const token = jwt.sign(payload, privateKey, {
            algorithm: 'RS256',
            expiresIn: '24h', 
            keyid: KEY_ID     
        });

        res.json({
            status: "200 OK",
            access_token: token,
            token_type: "bearer"
        });
    } catch (error) {
        // 🌟 혹시라도 토큰 서명 중 에러가 발생해도 서버가 죽지 않고 안전하게 에러를 반환합니다.
        console.error("JWT 발급 실패:", error.message);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

const PORT = 8000;
app.listen(PORT, () => {
    console.log(`Node.js Auth Server is running on port ${PORT}...`);
});