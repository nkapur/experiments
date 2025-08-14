# A simple script to provision an EKS cluster, EKS utilities and configure kubectl.
#
# Usage:
#   ./start-eks.sh up      -> Provisions the infrastructure.
#   ./start-eks.sh down    -> Safely tears down the infrastructure.

##### Prepare for Execution #####

# Exit immediately if a command exits with a non-zero status.
set -e

# Source the polling utilities
SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/../../lib/shell/polling_utils.sh"

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
  echo "✅ All tools are present."
}

## Function to provision the EKS cluster using Terraform
terraform_up() {
  echo "🚀 Bringing up EKS cluster with Terraform..."
  terraform init
  terraform apply -auto-approve -target=module.eks

  # set up kubectl
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

  # install the rest
  terraform apply -auto-approve
  echo "✅ Terraform apply complete."
}

## 🔽 NEW: Function to safely tear down the cluster
teardown() {
  # Trigger poll_for_output and fail if response not as expected
  poll_for_output "kubectl get ingress -A" "No resources found"

  # TODO (navneetkapur): Convert to a automated check
  read -p "Are you sure you have run kubectl delete on all the apps? (y/n) " -n 1 -r

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo "🔥 Starting safe teardown process..."
    terraform destroy -auto-approve
    echo "✅ Teardown complete."
  fi
}

##### Main Execution #####
main() {
  # Default to "up" if no argument is provided
  ACTION=${1:-up}

  check_dependencies

  if [ "$ACTION" == "up" ]; then
    terraform_up
    # configure_kubectl
    # apply_manifests
    echo "🎉 EKS cluster setup is complete!"
  elif [ "$ACTION" == "down" ] || [ "$ACTION" == "destroy" ]; then
    teardown
  else
    echo "❌ Invalid action: $ACTION"
    echo "Usage: $0 [up|down|destroy]"
    exit 1
  fi
}

# Run the main function, passing all script arguments to it
main "$@"