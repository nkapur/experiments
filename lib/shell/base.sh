# Set the region where your EKS cluster is defined
AWS_REGION="us-west-2"
CLUSTER_NAME="experiments-kube-cluster"

# Tooling Dependency pre-checks
check_dependencies() {
  echo "🔎 Checking for required tools (terraform, aws, kubectl)..."
  if ! command -v terraform &> /dev/null; then
    echo "❌ Error: terraform is not installed. Please install it first."
    exit 1
  fi
  if ! command -v aws &> /dev/null; then
    echo "❌ Error: aws-cli is not installed. Please install it first."
    exit 1
  fi
  if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed. Please install it first."
    exit 1
  fi
  if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed. Please install it first."
    exit 1
  fi
  echo "✅ All tools are present."
}

check_kube_cluster() {
  echo "Starting EKS cluster health check for '$CLUSTER_NAME' in region '$AWS_REGION'..."

  # Step 1: Verify kubectl access and configure if needed
  echo "\n--- 1. Verifying kubectl access to the cluster... ---"
  if ! kubectl version --short &> /dev/null; then
    echo "⚠️  kubectl is not configured correctly. Attempting to update kubeconfig now..."
    if ! aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"; then
      echo "❌ Failed to update kubeconfig. Please check your AWS credentials and permissions."
      exit 1
    fi
    echo "✅ kubeconfig updated successfully. Continuing check..."
  else
      echo "✅ kubectl access confirmed."
  fi

  # Step 2: Check the EKS control plane status
  echo "\n--- 2. Checking EKS Control Plane Status (via AWS) ---"
  STATUS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.status" --output text 2>/dev/null)

  if [ "$STATUS" = "ACTIVE" ]; then
    echo "✅ Control Plane Status: $STATUS"
  else
    echo "❌ Control Plane Status: $STATUS"
  fi

  # Step 3: Check the status of the worker nodes
  echo ""
  echo "--- 3. Checking Worker Node Status (via kubectl) ---"
  kubectl get nodes

  # Step 4: Check the status of critical system pods
  echo ""
  echo "--- 4. Checking Core System Pods in 'kube-system' ---"
  kubectl get pods -n kube-system

  echo ""
  echo "Health check complete."
}