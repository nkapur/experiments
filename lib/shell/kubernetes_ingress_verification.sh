#!/bin/bash

# ---
# This script verifies that a Kubernetes deployment and its associated Ingress
# are fully set up and healthy on AWS EKS. It checks three things in sequence:
# 1. The deployment rollout is complete.
# 2. The Ingress resource has been assigned a DNS address by the ALB controller.
# 3. The targets in the ALB's target group are all reporting a 'healthy' state.
# ---

# --- Configuration ---
TIMEOUT_SECONDS=600 # 10 minutes

# --- Helper Functions ---

# Prints a formatted header message.
function print_header() {
  echo ""
  echo "----------------------------------------------------"
  echo "=> $1"
  echo "----------------------------------------------------"
}

# --- Verification Functions ---

# Waits for the specified deployment to complete its rollout.
function wait_for_deployment() {
  local deployment_name="$1"
  local namespace="$2"

  print_header "Step 1: Waiting for deployment '$deployment_name' to be ready..."
  if ! kubectl rollout status deployment "$deployment_name" -n "$namespace" --timeout="${TIMEOUT_SECONDS}s"; then
    echo "Error: Deployment rollout failed or timed out."
    exit 1
  fi
  echo "Success: Deployment is ready."
}

# Waits for the specified Ingress to receive a hostname from the load balancer.
function wait_for_ingress_address() {
  local ingress_name="$1"
  local namespace="$2"
  local ingress_hostname

  print_header "Step 2: Waiting for Ingress '$ingress_name' to receive an address..."
  
  local jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  local end_time=$((SECONDS + TIMEOUT_SECONDS))

  while [[ -z $(kubectl get ingress "$ingress_name" -n "$namespace" -o jsonpath="$jsonpath" 2>/dev/null) ]]; do
    if [ $SECONDS -gt $end_time ]; then
      echo "Error: Timed out waiting for Ingress address."
      kubectl describe ingress "$ingress_name" -n "$namespace"
      exit 1
    fi
    echo "Waiting for Ingress address..."
    sleep 15
  done

  ingress_hostname=$(kubectl get ingress "$ingress_name" -n "$namespace" -o jsonpath="$jsonpath")
  if [ -z "$ingress_hostname" ]; then
      echo "Error: Could not retrieve Ingress hostname."
      exit 1
  fi
  echo "Success: Ingress has been assigned address: $ingress_hostname"
}

# Waits for all targets in an ALB Target Group to become healthy.
function wait_for_target_health() {
  local ingress_name="$1"
  
  print_header "Step 3: Waiting for ALB targets to become healthy..."
  local target_group_arn
  target_group_arn=$(aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName, 'k8s-')].TargetGroupArn" --output text | xargs -n1 | head -n 1)

  if [ -z "$target_group_arn" ]; then
    echo "Error: Could not find Target Group ARN for Ingress '$ingress_name'."
    echo "It may take a moment for tags to propagate. Please try again."
    exit 1
  fi
  echo "Found Target Group ARN: $target_group_arn"

  local end_time=$((SECONDS + TIMEOUT_SECONDS))
  while true; do
    if [ $SECONDS -gt $end_time ]; then
      echo "Error: Timed out waiting for targets to become healthy."
      aws elbv2 describe-target-health --target-group-arn "$target_group_arn"
      exit 1
    fi

    local health_status
    health_status=$(aws elbv2 describe-target-health --target-group-arn "$target_group_arn" --query "TargetHealthDescriptions[*].TargetHealth.State" --output json)

    # Expected to look similar to:
    #  [
    #   "healthy",
    #   "healthy"
    #  ]
    # echo "Current target health status: $health_status"

    # Check if health_status has any which are not "healthy"
    # Direct Grep below does NOT work because of the JSON array format
    if echo "$health_status" | jq -e 'any(. != "healthy")' >/dev/null; then
      echo "Waiting for all targets to be healthy. Current status: $health_status"
      sleep 20
    else
      echo "Success: All targets are healthy."
      break
    fi
  done
}

# --- Main Execution ---

function main() {
  if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <namespace> <deployment-name> <ingress-name>"
    exit 1
  fi

  local namespace="$1"
  local deployment_name="$2"
  local ingress_name="$3"

  wait_for_deployment "$deployment_name" "$namespace"
  wait_for_ingress_address "$ingress_name" "$namespace"
  wait_for_target_health "$ingress_name"

  print_header "Verification Complete: All resources are set up and ready!"
}

# Execute the main function with all provided command-line arguments
main "$@"
