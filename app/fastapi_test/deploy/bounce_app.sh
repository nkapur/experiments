# Exit immediately if a command exits with a non-zero status.
set -e

SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/../../../lib/shell/polling_utils.sh"

NAMESPACE="staging"
DEPLOYMENT="fastapi-test-deployment"
INGRESS="fastapi-test-ingress"

setup() {
  # Kubernetes Manifests
  kubectl apply -f $SCRIPT_DIR/k8s
  $SCRIPT_DIR/../../../lib/shell/kubernetes_ingress_verification.sh $NAMESPACE $DEPLOYMENT $INGRESS
  echo "✅ Kubernetes manifests applied."

  # DNS updates
  cd $SCRIPT_DIR/k8s/terraform
  terraform apply -auto-approve
  echo "✅ DNS records (and Terraform state) updated."
  cd -

  echo "✅ Deployment on Kubernetes cluster complete."
}

teardown() {
  echo "🔥 Starting safe teardown process..."
  kubectl delete -f $SCRIPT_DIR/k8s

  echo "Verifying ingress/LB resources are terminated..."
  poll_for_output "kubectl get ingress ${INGRESS} -n ${NAMESPACE}" '"${INGRESS}" not found'

  # Terraform destroy not recommended as TF sets up the container registry for the app which we still need
  echo "✅ Teardown complete."
}

##### Main Execution #####
main() {
  # Default to "up" if no argument is provided
  ACTION=${1:-up}

  if [ "$ACTION" == "up" ]; then
    setup
  elif [ "$ACTION" == "down" ] || [ "$ACTION" == "destroy" ]; then
    teardown
  else
    echo "❌ Invalid action: $ACTION"
    echo "Usage: $0 [up|down]"
    exit 1
  fi
}

# Run the main function, passing all script arguments to it
main "$@"