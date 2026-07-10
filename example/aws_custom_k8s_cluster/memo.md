
### ubuntu master node 에서 admin.conf 가져오기 


#### 1단계: 마스터 노드 내부에서 파일 복사 및 권한 개방 (마스터 노드에서 실행)

```bash

# master node 에 접속 하는 방법
# ssh ubuntu@<master node ip> -i k8s-lab-key.pem 

# 1. 일반 계정(ubuntu)이 접근할 수 있는 /tmp 폴더로 파일을 복사합니다.
sudo cp /etc/kubernetes/admin.conf /tmp/admin.conf

# 2. 복사한 파일의 소유자를 root에서 ubuntu 계정으로 변경합니다.
sudo chown ubuntu:ubuntu /tmp/admin.conf
```

#### 2단계: 내 PC(mgmt)로 안전하게 가져오기 (원래 있던 PC 터미널에서 실행)

```bash

# scp -i k8s-lab-key.pem ubuntu@<master node 의 ip>:/tmp/admin.conf ./aws-kubeconfig
scp -i k8s-lab-key.pem ubuntu@10.20.2.37:/tmp/admin.conf ./aws-kubeconfig

# 가지고온 파일을 ~/.kube/config  로  이동 시켜 놓으면 사용할수 있다. (파일 rename 또는 내용만 추출해서 합치기)

```