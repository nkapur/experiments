# Use this script to bring the application up or down.

set -e

ACTION=${1:-up}
APP_NAME=$2
DEPLOYMENT_MODE=${3:-staging}
source "${SCRIPT_DIR}/../../lib/shell/base.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
TERRAFORM_DIR="${SCRIPT_DIR}/../../app/${APP_NAME}/deploy/terraform"
REPO_ROOT="${SCRIPT_DIR}/../.."

# Verify Inputs
if [ -z "$APP_NAME" ] || [ -z "$DIRECTION" ] || [ -z "$DEPLOYMENT_MODE" ]; then
  echo "❌ Error: APP_NAME(=$APP_NAME), DIRECTION(=$DIRECTION), and DEPLOYMENT_MODE(=$DEPLOYMENT_MODE) must be set."
  exit 1
fi

# Verify Local environment deps
check_dependencies

# Verify Kube cluster is healthy and accessible
check_kube_cluster

setup() {
    # --- PREP ---
    echo "Setting up Helm chart for $APP_NAME..."
    helm repo add platform-modules https://nkapur.github.io/platform_modules
    helm repo update

    # --- KUBE DEPLOY ---
    echo "Setting up the App - assuming platform-modules is checked out locally"
    cd ${REPO_ROOT}/app/${APP_NAME}
    helm upgrade --install ${APP_NAME//_/-} \
        platform-modules/fastapi-service \
        --version 0.1.1 \
        -f ${REPO_ROOT}/../platform_modules/app_platform/helm/environments/staging-globals.yaml \
        -f ./deploy/helm/values-staging.yaml \
        --namespace staging \
        --create-namespace

    # --- DNS SETUP ---
    cd ${TERRAFORM_DIR}
    terraform init
    terraform apply -auto-approve
}

teardown() {
    echo "🔥 Starting safe teardown process..."
    cd ${REPO_ROOT}/app/${APP_NAME}
    helm uninstall ${APP_NAME//_/-} --namespace staging

    cd ${TERRAFORM_DIR}
    terraform destroy -auto-approve

    echo "Verifying ingress/LB resources are terminated..."
    INGRESS=${APP_NAME//_/-}-fastapi-service
    poll_for_output "kubectl get ingress ${INGRESS} -n ${DEPLOYMENT_MODE}" '"${INGRESS}" not found'

    # Terraform destroy not recommended as TF sets up the container registry for the app which we still need
    echo "✅ Teardown complete."
}

##### Main Execution #####
main() {
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