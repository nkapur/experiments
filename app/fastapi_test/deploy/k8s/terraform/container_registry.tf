# --- Amazon ECR Repository ---
# This resource creates a new private ECR repository to store Docker container images.

resource "aws_ecr_repository" "app_repository" {
  # --- Naming and Configuration ---
  # The name of your repository. This is what you'll use in your Docker push/pull commands.
  # e.g., <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/fastapi_test
  name = "fastapi_test"

  # --- Image Scanning ---
  # Automatically scans images for software vulnerabilities upon being pushed to the repository.
  # This is a highly recommended security best practice.
  image_scanning_configuration {
    scan_on_push = true
  }

  # --- Image Tag Immutability ---
  # Prevents image tags from being overwritten. For example, if you push 'my-app:latest'
  # and then push a new version with the same tag, the push will be denied.
  # This enforces versioning discipline and prevents accidental overwrites.
  # For development workflows, you might set this to "MUTABLE", but "IMMUTABLE" is safer for production.
  # TODO : Change to "IMMUTABLE" for production use.
  image_tag_mutability = "MUTABLE"

  # --- Tags for Resource Management ---
  # These tags help with cost allocation and identifying resources in the AWS console.
  tags = {
    Project   = "Apps in Experiments Repo"
    ManagedBy = "Terraform"
  }
}

# --- ECR Lifecycle Policy ---
# This resource attaches a policy to the ECR repository to automatically manage and
# clean up old images, which helps control storage costs.

resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = aws_ecr_repository.app_repository.name

  # The policy is defined in JSON format.
  policy = <<-EOT
  {
      "rules": [
          {
              "rulePriority": 1,
              "description": "Expire untagged images older than 14 days",
              "selection": {
                  "tagStatus": "untagged",
                  "countType": "sinceImagePushed",
                  "countUnit": "days",
                  "countNumber": 14
              },
              "action": {
                  "type": "expire"
              }
          },
          {
              "rulePriority": 2,
              "description": "Keep last 20 total images",
              "selection": {
                  "tagStatus": "any",
                  "countType": "imageCountMoreThan",
                  "countNumber": 20
              },
              "action": {
                  "type": "expire"
              }
          }
      ]
  }
  EOT
}

# --- Outputs ---
# These outputs provide useful information after the resources are created.

output "ecr_repository_url" {
  description = "The URL of the ECR repository. Used for Docker push/pull commands."
  value       = aws_ecr_repository.app_repository.repository_url
}

output "ecr_repository_name" {
  description = "The name of the ECR repository."
  value       = aws_ecr_repository.app_repository.name
}

