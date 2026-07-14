
### s3 버킷에 index.html 파일 올리기

```bash
# html 폴더에서 terminal 을 열록 아래의 명령어로 s3 버킷에 파일을 업로드 한다
aws s3 cp index.html s3://my-microservice-frontend-bucket-123/index.html
```

### terraform destroy 할때는  s3 버킷이 비어 있어야 된다 

```bash
# 저장된 모든 파일을 삭제후에  
aws s3 rm s3://my-microservice-frontend-bucket-123 --recursive
# terraform 으로 삭제 한다
terraform destroy --auto-approve
```