data "aws_iam_user" "local_user" {
  user_name = "navneet_laptop"
}


data "aws_iam_policy_document" "app_deployer_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [data.aws_iam_user.local_user.arn]
    }
  }
}

resource "aws_iam_role" "app_deployer_role" {
  for_each = var.deployer_roles
  name     = each.value.name

  assume_role_policy = data.aws_iam_policy_document.app_deployer_assume_role.json
}

resource "aws_iam_policy" "app_deployer_policy" {
  name        = "AppDeployerPolicy"
  description = "Policy for EKS application deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_deployer_attachment" {
  for_each   = var.deployer_roles
  role       = aws_iam_role.app_deployer_role[each.key].name
  policy_arn = aws_iam_policy.app_deployer_policy.arn
}

output "deployer_role_arns" {
  description = "The ARNs of the created IAM roles for deployers."
  value       = { for k, role in aws_iam_role.app_deployer_role : k => role.arn }
}
