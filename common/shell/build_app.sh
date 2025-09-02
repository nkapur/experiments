SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
APP_NAME=$1
TERRAFORM_DIR="${SCRIPT_DIR}/../../app/${APP_NAME}/deploy/terraform"

# Commandline argument: EKS Cluster Up or Not
EKS_UP_FLAG=${2:-false}

# Verify the input params are provided
if [ -z "$APP_NAME" ] || [ -z "$EKS_UP_FLAG" ]; then
  echo "Error: One or more of APP_NAME (=${APP_NAME}) or EKS_UP_FLAG (=${EKS_UP_FLAG}) is not set."
  exit 1
fi

# --- CREATE THE REPOSITORY ---

cd "${TERRAFORM_DIR}"
terraform init
terraform apply \
    -target=module.fastapi_service.aws_ecr_repository.app_repository \
    -auto-approve


# --- BUILD AND INSTALL IMAGE ---
./${SCRIPT_DIR}/docker_build.sh $APP_NAME

# --- TODO - Move below to bounce_app.sh. See example in fastapi_test ---
# --- DEPLOY TO EKS ---
# if [ "$EKS_UP_FLAG" = true ]; then
#     echo "Deploying to EKS Cluster..."
#     echo "Not Implemented Yet!"

    # --- KUBE DEPLOY ---
    # helm upgrade --install auto-govern \
    #     platform-modules/fastapi-service \
    #     --version 0.1.1 \
    #     -f ~/develop/platform_modules/app_platform/helm/environments/staging-globals.yaml \
    #     -f ./deploy/helm/values-staging.yaml \
    #     --namespace staging \
    #     --create-namespace

    # --- DNS SETUP ---
    # cd "${TERRAFORM_DIR}"
    # terraform init
    # terraform apply -auto-approve
# fi
