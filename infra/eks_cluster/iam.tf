##########################################
# Create IAM user for Staging Service
##########################################

resource "aws_iam_user" "staging_service_user" {
  name = "staging-service-user"
}

# Attach an inline policy to the staging service user (to allow interaction with EKS)
resource "aws_iam_policy" "staging_service_user_policy" {
  name        = "staging-service-user-policy"
  description = "Policy for staging service user to access EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:DescribeCluster"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:DescribeNodegroup"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "staging_service_user_attach_policy" {
  user       = aws_iam_user.staging_service_user.name
  policy_arn = aws_iam_policy.staging_service_user_policy.arn
}


##########################################
# Create IAM user for Prod Service
##########################################

resource "aws_iam_user" "prod_service_user" {
  name = "prod-service-user"
}

# Attach an inline policy to the prod service user (to allow interaction with EKS)
resource "aws_iam_policy" "prod_service_user_policy" {
  name        = "prod-service-user-policy"
  description = "Policy for prod service user to access EKS"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:DescribeCluster"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:DescribeNodegroup"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "prod_service_user_attach_policy" {
  user       = aws_iam_user.prod_service_user.name
  policy_arn = aws_iam_policy.prod_service_user_policy.arn
}

##########################################
# Create IAM Role for Admins to Assume
##########################################
resource "aws_iam_role" "admin_user_eks_role" {
  name = "admin-user-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::396724649279:user/navneet_laptop"
        }
      }
    ]
  })
}

# Attach EKS permissions to the admin user role
resource "aws_iam_policy" "admin_user_eks_policy" {
  name        = "admin-user-eks-policy"
  description = "Policy to allow admin user to interact with EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:DescribeCluster"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:DescribeNodegroup"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:UpdateClusterConfig"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:CreateCluster"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "eks:DeleteCluster"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_user_attach_policy" {
  role       = aws_iam_role.admin_user_eks_role.name
  policy_arn = aws_iam_policy.admin_user_eks_policy.arn
}
