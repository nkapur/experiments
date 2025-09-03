# Use this script to bring the application up or down.

set -e

ACTION=${1:-up}
APP_NAME=$2
DEPLOYMENT_MODE=${3:-staging}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
TERRAFORM_DIR="${SCRIPT_DIR}/../../app/${APP_NAME}/deploy/terraform"
REPO_ROOT="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../../lib/shell/base.sh"
source "${SCRIPT_DIR}/../../lib/shell/polling_utils.sh"

# Verify Inputs
if [ -z "$APP_NAME" ] || [ -z "$ACTION" ] || [ -z "$DEPLOYMENT_MODE" ]; then
  echo "❌ Error: APP_NAME(=$APP_NAME), ACTION(=$ACTION), and DEPLOYMENT_MODE(=$DEPLOYMENT_MODE) must be set."
  exit 1
fi

# Verify Local environment deps
check_dependencies

# set up kubectl
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

# Verify Kube cluster is healthy and accessible
check_kube_cluster

# Assume role to deploy the app
DEPLOYMENT_ROLE_ARN="arn:aws:iam::396724649279:role/AppDeployerRole-${DEPLOYMENT_MODE}"
aws sts assume-role --role-arn $DEPLOYMENT_ROLE_ARN --role-session-name $APP_NAME

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
        -f ${REPO_ROOT}/../platform_modules/app_platform/helm/environments/${DEPLOYMENT_MODE}-globals.yaml \
        -f ./deploy/helm/values-${DEPLOYMENT_MODE}.yaml \
        --namespace ${DEPLOYMENT_MODE} \
        --create-namespace

    # --- DNS SETUP ---
    echo "Setting up DNS records via Terraform..."
    cd ${TERRAFORM_DIR}
    terraform init
    terraform apply -auto-approve

    echo "The LB should be ready within 10-15 minutes..."
    ALB_ARN=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[*].LoadBalancerArn" \
        --output text | xargs -n1 aws elbv2 describe-tags --resource-arns \
        | jq '.TagDescriptions[] | select(.Tags[] | select(.Key=="ingress.k8s.aws/stack" and .Value=="${DEPLOYMENT_MODE}/${APP_NAME//_/-}-fastapi-service"))' \
        | jq -r '.ResourceArn')

    ALB_READY_CHECK="aws elbv2 describe-load-balancers --load-balancer-arns ${ALB_ARN} | jq -r '.LoadBalancers[0].State.Code'"
    poll_for_output "${ALB_READY_CHECK}" 'active' 90
    echo "✅ ALB ARN: $ALB_ARN"
}

teardown() {
    echo "🔥 Starting safe teardown process..."

    # --- Destroy DNS records and other TF-managed resources ---
    cd ${TERRAFORM_DIR}
    terraform init
    terraform destroy -target=module.fastapi_service.aws_route53_record.app_cname -auto-approve
    echo "✅ Terraform Destroy complete"

    # --- Destroy Kubernetes resources ---
    cd ${REPO_ROOT}/app/${APP_NAME}
    helm uninstall ${APP_NAME//_/-} --namespace ${DEPLOYMENT_MODE}
    echo "✅ Helm Uninstall complete"

    # --- Verify ingress/LB resources are terminated ---
    echo "Verifying ingress/LB resources are terminated..."
    local INGRESS=${APP_NAME//_/-}-fastapi-service
    poll_for_output "kubectl get ingress ${INGRESS} -n ${DEPLOYMENT_MODE}" "\"$INGRESS\" not found" 30 30

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