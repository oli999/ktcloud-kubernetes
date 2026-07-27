
# ---------------------------------------------------------
# [IRSA 설정] Jenkins가 ECR에 접근하기 위한 IAM 권한 구성
# ---------------------------------------------------------

# 현재 AWS 계정 정보(Account ID)를 가져오기 위한 필수 데이터 소스
data "aws_caller_identity" "current" {}

# 현재 사용 중인 EKS 클러스터 정보 가져오기 (이름은 실제 클러스터명으로 변경)
data "aws_eks_cluster" "this" {
  name = "hello-eks" # 실제 EKS 클러스터 이름으로 변경해 주세요!
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
          # 핵심: jenkins 네임스페이스의 'jenkins-sa'라는 이름의 ServiceAccount만 허용
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
# ArgoCD를 통한 Jenkins 배포 (GitOps 방식)
# ---------------------------------------------------------
resource "argocd_application" "jenkins_app" {
  metadata {
    name      = "my-jenkins"
    namespace = "argocd"
  }
  
  spec {
    project = "default"
    
    source {
      # 1. 젠킨스 공식 Helm Repository 지정
      repo_url        = "https://charts.jenkins.io"
      chart           = "jenkins"
      target_revision = "5.9.34"
      
      # 2. Helm 차트에 값(Values) 주입
      helm {
        # 기존에 사용하던 로컬 values.yaml 파일의 내용을 통째로 읽어서 ArgoCD에 전달합니다.
        values = file("${path.module}/jenkins/jenkins-values.yaml")
        
        # IRSA 동적 주입: 테라폼이 방금 생성한 IAM Role ARN을 파라미터로 덮어씌웁니다.
        # (기존 helm_release의 'set' 블록과 완벽히 동일한 역할입니다)
        parameter {
          name  = "serviceAccount.create"
          value = "true"
        }
        parameter {
          name  = "serviceAccount.name"
          value = "jenkins-sa"
        }
        parameter {
          # 백슬래시(\) 이스케이프 처리에 주의하세요.
          name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
          value = aws_iam_role.jenkins_irsa_role.arn 
        }
      }
    }
    
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "jenkins"
    }
    
    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
      # 대소문자에 주의하세요: CreateNamespace 가 정확한 옵션명입니다.
      sync_options = ["CreateNamespace=true"] 
    }
  }
}