
### vscode 에 helm chart 를 편하게 작성하기 위한 플러그인 설치하기

- Helm Intellisense 설치
- YAML by Red Hat 설치

# helm template 을 해석한 결과 출력
helm template my-release . 

# helm template 을 해석한 결과를 result.yaml 파일로 얻어내기
helm template my-release . > ./docs/result.yaml

# helm install 을 모의로 해보기
helm install my-release . --dry-run
