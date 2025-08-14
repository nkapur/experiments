#!/bin/bash

# ---
# Polls for a specific string in the output of a command.
#
# Usage: poll_for_output "command_to_run" "expected_output_string" [max_attempts]
#
# Arguments:
#   $1: The command to execute, enclosed in quotes.
#   $2: The string to search for in the command's output.
#   $3: (Optional) The maximum number of attempts before timing out. Defaults to 30.
#
# Example (kubectl):
#   poll_for_output "kubectl get ingress -A" "No resources found"
#
# Example (aws cli):
#   CLUSTER_NAME="my-cluster"
#   CMD="aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text"
#   poll_for_empty_output "$CMD"
# ---
function poll_for_output() {
  local cmd_to_run="$1"
  local expected_output="$2"
  local max_attempts=${3:-30} # Default to 30 attempts if not provided
  local sleep_interval=10
  local count=0

  echo "Polling for command to contain: \"$expected_output\""
  echo "Command: $cmd_to_run"
  echo "----------------------------------------------------"

  # The 'eval' command is used to correctly execute the command string,
  # which may contain pipes and quotes.
  while ! eval "$cmd_to_run" 2>&1 | grep -q "$expected_output"; do
    count=$((count + 1))
    if [ "$count" -ge "$max_attempts" ]; then
      echo "Timeout reached after $max_attempts attempts. The expected output was not found."
      return 1 # Return a failure status code
    fi
    echo "Attempt $count/$max_attempts: Expected output not found. Waiting ${sleep_interval}s..."
    sleep "$sleep_interval"
  done

  echo "Success! The command output now contains \"$expected_output\"."
  return 0 # Return a success status code
}


# ---
# A specialized version of the poll function to check for EMPTY output.
#
# Usage: poll_for_empty_output "command_to_run" [max_attempts]
# ---
function poll_for_empty_output() {
  local cmd_to_run="$1"
  local max_attempts=${2:-30} # Default to 30 attempts
  local sleep_interval=10
  local count=0

  echo "Polling for command to produce EMPTY output..."
  echo "Command: $cmd_to_run"
  echo "----------------------------------------------------"

  # The '-z' flag checks if the output string is empty.
  while [ ! -z "$(eval "$cmd_to_run")" ]; do
    count=$((count + 1))
    if [ "$count" -ge "$max_attempts" ]; then
      echo "Timeout reached after $max_attempts attempts. The command output is still not empty."
      return 1
    fi
    echo "Attempt $count/$max_attempts: Output is not empty. Waiting ${sleep_interval}s..."
    sleep "$sleep_interval"
  done

  echo "Success! The command now produces empty output."
  return 0
}