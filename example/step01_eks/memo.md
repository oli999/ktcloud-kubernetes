
# AWS CLI를 이용해 접속 정보 가져오기
aws eks update-kubeconfig --region ap-northeast-2 --name hello-eks
# context 목록 얻어오기 
kubectl config get-contexts

# 현재 선택된 context 조회
kubectl config current-context

# local k8s 클러스터로 context 변경 
k config use-context kubernetes-admin@kubernetes

# 특정 context 삭제
k config delete-context <context 이름>
