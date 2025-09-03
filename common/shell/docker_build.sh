#!/usr/bin/env bash

# Docker build script for FastAPI application using the most recent release tag.
# This script is expected to run in an app-specific CI/CD pipeline currently, it
# is designed to be easy to parameterize and generalize into the beginnings of a build
# and/or deploy platform.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# APP_NAME is a commandline parameter
APP_NAME="$1"
RELEASE_VERSION=${2:-$(gh release view --json tagName,name --jq '.tagName')}
BUILD_FROM_ROOT=${3:-false}

# Set working directory based on where the script is located
if [ "$BUILD_FROM_ROOT" = true ]; then
  WORKING_DIR="${SCRIPT_DIR}/../../"
  BUILDX_ARG="-f app/${APP_NAME}/Dockerfile"
else
  WORKING_DIR="${SCRIPT_DIR}/../../app/${APP_NAME}"
  BUILDX_ARG="-f Dockerfile"
fi

echo "Changing working directory to ${WORKING_DIR}"
cd "${WORKING_DIR}"

EPOCH=$(date +%s)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
WORKING_BRANCH=experiments-docker-build-$APP_NAME-$RELEASE_VERSION-$EPOCH
if [ -z "$RELEASE_VERSION" ]; then
  echo "Release version not found. Please ensure you have a valid release tag."
  exit 1
fi

ECR_REPO_PREFIX="396724649279.dkr.ecr.us-west-2.amazonaws.com"
ECR_REPO="$ECR_REPO_PREFIX/$APP_NAME"  # TODO: ECR repository URL should be pulled in from SSM


aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REPO_PREFIX


# Simple Arrays
declare -a commands=(
  "git fetch; git checkout -b $WORKING_BRANCH $RELEASE_VERSION"
  "docker buildx build --platform=linux/arm64 $BUILDX_ARG -t $APP_NAME:latest-arm64 --load ."
  "docker tag $APP_NAME:latest-arm64 $ECR_REPO:latest-arm64"
  "docker tag $APP_NAME:latest-arm64 $ECR_REPO:$RELEASE_VERSION-arm64"
  "docker push $ECR_REPO:latest-arm64"
  "docker push $ECR_REPO:$RELEASE_VERSION-arm64"
  "git checkout $CURRENT_BRANCH; git branch -D $WORKING_BRANCH"
)
declare -a error_messages=(
  "Release tag fetch failed. Git checkout failed for release $RELEASE_VERSION. Please check your repository and try again."
  "Docker build failed. Please check the Dockerfile and try again."
  "Docker latest tag failed to attach. Please check the Docker image and try again."
  "Docker release tag failed to attach. Please check the Docker image and try again."
  "Docker push failed. Please check your Docker credentials and try again."
  "Docker release push failed. Please check your Docker credentials and try again."
  "Docker build cleanup failed for working branch $WORKING_BRANCH. Please check the branch and try again."
)

# Loop through commands using indexed array, which preserves order
echo "--- Starting command execution loop ---"
for i in "${!commands[@]}"; do
  cmd="${commands[$i]}"
  error_msg="${error_messages[$i]}"

  echo -e "\n--- Executing command: \"$cmd\" ---"
  eval "$cmd"
  if [ $? -ne 0 ]; then
    echo "Command failed with exit code $?."
    echo "Error Message: $error_msg"
    exit 1
  fi
done

echo "All commands executed successfully."
