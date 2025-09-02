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
source "${SCRIPT_DIR}/../../lib/shell/base.sh"
source "${SCRIPT_DIR}/../../lib/shell/polling_utils.sh"

## Function to provision the EKS cluster using Terraform
terraform_up() {
  echo "🚀 Bringing up EKS cluster with Terraform..."
  cd ${SCRIPT_DIR}
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
  # set up kubectl
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

  # Trigger poll_for_output and fail if response not as expected
  poll_for_output "kubectl get ingress -A" "No resources found"

  # TODO (navneetkapur): Convert to a automated check
  
  CONDITION_SATISFIED=false
  if [[ $ON_RUNNER == true ]]; then
    CONDITION_SATISFIED=true
  else
    # Check if the user has run kubectl delete on all the apps
    echo "Please ensure you have run 'kubectl delete' on all the applications before proceeding."
    read -p "Have you done that? (y/n) " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      CONDITION_SATISFIED=true
    fi
  fi

  if [[ $CONDITION_SATISFIED == true ]]; then
    echo "🔥 Starting safe teardown process..."
    cd ${SCRIPT_DIR}
    terraform init
    terraform destroy -auto-approve
    echo "✅ Teardown complete."
  fi
}

##### Main Execution #####
main() {

  # Default to "up" if no argument is provided
  ACTION=${1:-up}
  ON_RUNNER=${2:-false}  # [LOCAL|GITHUB] Defaults to LOCAL

  check_dependencies

  if [ "$ACTION" == "up" ]; then
    terraform_up
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