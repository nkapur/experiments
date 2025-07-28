#!/usr/bin/env bash

# Docker build script for FastAPI application using the most recent release tag.
# This script is expected to run in an app-specific CI/CD pipeline currently, it
# is designed to be easy to parameterize and generalize into the beginnings of a build
# and/or deploy platform.

SCRIPT_PATH=$0
SCRIPT_DIR=$(dirname "$0")
APP_NAME="fastapi_test"
cd "$SCRIPT_DIR"

EPOCH=$(date +%s)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
RELEASE_VERSION=$(gh release view --json tagName,name --jq '.tagName')
WORKING_BRANCH=experiments-docker-build-$APP_NAME-$RELEASE_VERSION-$EPOCH
if [ -z "$RELEASE_VERSION" ]; then
  echo "Release version not found. Please ensure you have a valid release tag."
  exit 1
fi

ECR_REPO="396724649279.dkr.ecr.us-west-2.amazonaws.com/$APP_NAME"  # TODO: ECR repository URL should be pulled in from SSM

# Simple Arrays
declare -a commands=(
  "git fetch; git checkout -b $WORKING_BRANCH $RELEASE_VERSION"
  "docker buildx build --platform=linux/amd64 -t $APP_NAME:latest-amd64 --load ."
  "docker tag $APP_NAME:latest-amd64 $ECR_REPO:latest-amd64"
  "docker tag $APP_NAME:latest-amd64 $ECR_REPO:$RELEASE_VERSION-amd64"
  "docker push $ECR_REPO:latest-amd64"
  "docker push $ECR_REPO:$RELEASE_VERSION-amd64"
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
