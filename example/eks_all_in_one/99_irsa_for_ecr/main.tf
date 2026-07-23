# 1. 현재 사용 중인 EKS 클러스터 정보 가져오기 (이름은 실제 클러스터명으로 변경)
data "aws_eks_cluster" "this" {
  name = "my-eks-cluster" 
}

# 2. Jenkins가 사용할 IAM Role 생성 및 Trust Policy(신뢰 정책) 설정
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

# 3. 위에서 만든 Role에 ECR 접근 권한(PowerUser) 부여
resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# 4. Helm에 주입할 Role ARN 출력
output "jenkins_irsa_role_arn" {
  value = aws_iam_role.jenkins_irsa_role.arn
}