SCRIPT_DIR="$(dirname "$0")"
APP_NAME="auto_govern"
TERRAFORM_DIR="${SCRIPT_DIR}/../../app/${APP_NAME}/deploy/terraform"

# Commandline argument: EKS Cluster Up or Not
EKS_UP_FLAG=${1:-false}

# --- CREATE THE REPOSITORY ---

cd "${TERRAFORM_DIR}"
terraform init
terraform apply \
    -target=module.fastapi_service.aws_ecr_repository.app_repository \
    -auto-approve


# --- BUILD AND INSTALL IMAGE ---
./${SCRIPT_DIR}/../../lib/docker_build.sh $APP_NAME

# --- TODO - Move below to bounce_app.sh. See example in fastapi_test ---
# --- DEPLOY TO EKS ---
# if [ "$EKS_UP_FLAG" = true ]; then
#     echo "Deploying to EKS Cluster..."
#     echo "Not Implemented Yet!"
    # --- KUBE MANIFESTS ---
    # ...

    # --- DNS SETUP ---
    # cd "${TERRAFORM_DIR}"
    # terraform init
    # terraform apply -auto-approve
fi
