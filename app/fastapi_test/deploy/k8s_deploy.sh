# Exit immediately if a command exits with a non-zero status.
set -e

SCRIPT_DIR=$(dirname "$0")

# Kubernetes Manifests
kubectl apply -f $SCRIPT_DIR/k8s
echo "✅ Kubernetes manifests applied."

# DNS updates
cd $SCRIPT_DIR/k8s/terraform
terraform apply -auto-approve
echo "✅ DNS records (and Terraform state) updated."
cd -

echo "✅ Deployment on Kubernetes cluster complete."