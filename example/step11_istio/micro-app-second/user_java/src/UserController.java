
// com.nimbusds:nimbus-jose-jwt:9.37.3  dependency가 필요하다
import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.web.bind.annotation.*;

import javax.annotation.PostConstruct;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Date;
import java.util.Map;

@RestController
@RequestMapping("/user")
public class AuthController {

    private RSAKey rsaJWK;
    private final String KEY_ID = "k8s-prime-key-id";

    // ---------------------------------------------------------
    // [1] 서버 기동 시 미리 생성된 키 파일 로드 및 RSAKey 객체 초기화
    // ---------------------------------------------------------
    @PostConstruct
    public void initKeys() throws Exception {
        // 프로젝트 루트에 있는 pem 파일을 읽어옵니다. (실무에서는 경로 설정 주의)
        String privateKeyContent = new String(Files.readAllBytes(Paths.get("private_key.pem")));
        String publicKeyContent = new String(Files.readAllBytes(Paths.get("public_key.pem")));

        // nimbus 라이브러리가 PEM 문자열을 분석하여 자동으로 JWK 객체로 변환해 줍니다!
        JWK parsedJWK = JWK.parseFromPEMEncodedObjects(publicKeyContent + "\n" + privateKeyContent);
        
        // Istio가 검증할 때 사용할 kid(Key ID)를 명시적으로 세팅하여 저장합니다.
        this.rsaJWK = new RSAKey.Builder((RSAKey) parsedJWK)
                .keyID(KEY_ID)
                .build();
    }

    // ---------------------------------------------------------
    // [2] 핵심 엔드포인트: Istio가 읽어갈 JWKS 정보 노출
    // ---------------------------------------------------------
    @GetMapping("/.well-known/jwks.json")
    public Map<String, Object> getJwks() {
        // 내부적으로 공개키만 추출(toPublicJWK)하여 표준 JWKS JSON 규격으로 한 방에 변환해 줍니다.
        return new JWKSet(this.rsaJWK.toPublicJWK()).toJSONObject();
    }

    // ---------------------------------------------------------
    // [3] 로그인 처리 구역 교정 (JWT 발급)
    // ---------------------------------------------------------
    @PostMapping("/login")
    public Map<String, Object> generateUserToken(@RequestBody Map<String, String> data) throws JOSEException {
        String username = data.getOrDefault("userName", "Unknown");

        // 유효기간 24시간 설정
        long nowTime = System.currentTimeMillis();
        Date issueTime = new Date(nowTime);
        Date expirationTime = new Date(nowTime + (24 * 60 * 60 * 1000L)); 

        // 페이로드(Claims) 구성
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(username)
                .expirationTime(expirationTime)
                .issuer("http://svc-fastapi-user:8000/user/login")
                .claim("role", "수강생")
                .build();

        // 헤더에 kid 명찰 부착 및 서명 알고리즘 지정
        JWSHeader header = new JWSHeader.Builder(JWSAlgorithm.RS256)
                .keyID(KEY_ID)
                .build();

        // 토큰 생성 및 비공개키로 서명
        SignedJWT signedJWT = new SignedJWT(header, claimsSet);
        signedJWT.sign(new RSASSASigner(this.rsaJWK));
        
        // 최종 문자열 토큰 생성
        String token = signedJWT.serialize();

        // 응답 반환
        return Map.of(
                "status", "200 OK",
                "access_token", token,
                "token_type", "bearer"
        );
    }
}