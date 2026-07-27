# 05_jenkins/main.tf

terraform {
  required_providers {
    # 1. AWS 자원(IAM) 생성을 위한 provider 추가
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # 2. terraform 으로 k8s 자원들을 provision 할수 있도록 provider 추가 
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30" 
    }
    # 3. terraform 으로 helm chart 를 직접 배포 가능하도록 하는 provider 추가
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

# AWS 리전 설정 (필요에 따라 변경)
provider "aws" {
  region = "ap-northeast-2"
}

# 클러스터 접속정보 (local k8s 를 바라 보도록 context 가 변경되어 있어야 한다)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# helm provider 가 동작하려면 config 파일 정보를 전달해야 한다. 
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# ---------------------------------------------------------
# [IRSA 설정] Jenkins가 ECR에 접근하기 위한 IAM 권한 구성
# ---------------------------------------------------------

# 현재 AWS 계정 정보(Account ID)를 가져오기 위한 필수 데이터 소스
data "aws_caller_identity" "current" {}

# 현재 사용 중인 EKS 클러스터 정보 가져오기 (이름은 실제 클러스터명으로 변경)
data "aws_eks_cluster" "this" {
  name = "hello-eks" # 🚨 실제 EKS 클러스터 이름으로 변경해 주세요!
}

# Jenkins가 사용할 IAM Role 생성 및 Trust Policy(신뢰 정책) 설정
resource "aws_iam_role" "jenkins_irsa_role" {
  name = "jenkins-ecr-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # EKS 클러스터의 OIDC 공급자를 통해 인증
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          # 🚨 핵심: jenkins 네임스페이스의 'jenkins-sa'라는 이름의 ServiceAccount만 허용
          "StringEquals" = {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:jenkins:jenkins-sa"
          }
        }
      }
    ]
  })
}

# 위에서 만든 Role에 ECR 접근 권한(PowerUser) 부여
resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ---------------------------------------------------------
# [Helm 배포] Jenkins 설치 및 IRSA 권한(ServiceAccount) 주입
# ---------------------------------------------------------

resource "helm_release" "my_jenkins" {
  name             = "my-jenkins" 
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.9.34"
  namespace        = "jenkins"
  create_namespace = true

  values = [
    file("${path.module}/jenkins-values.yaml")
  ]

  # 🚨 IRSA 핵심 연동 파트: 위에서 만든 IAM 역할(ARN)을 젠킨스 ServiceAccount에 동적으로 꽂아줍니다.
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "jenkins-sa" # IRSA Trust Policy의 조건과 정확히 일치해야 합니다.
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.jenkins_irsa_role.arn
  }
}

# Helm에 주입된 Role ARN 출력
output "jenkins_irsa_role_arn" {
  value = aws_iam_role.jenkins_irsa_role.arn
}