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
