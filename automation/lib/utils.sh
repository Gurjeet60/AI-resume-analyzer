#!/bin/bash
# Common utilities

# Colors and logging
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# ---------- Constants ----------
PROJECT_NAME="ai-resume-analyzer"
CLUSTER_NAME="ai-resume-analyzer-dev"
NODEGROUP_NAME="ai-resume-analyzer-dev-nodes"
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-716228812170}"
APP_NAMESPACE="resume"
MONITORING_NAMESPACE="monitoring"

# ---------- Helper functions ----------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

retry() {
  local max_attempts="$1"
  local delay="$2"
  shift 2
  local attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    if "$@"; then
      return 0
    fi
    echo "${YELLOW}Attempt $attempt/$max_attempts failed — retrying in ${delay}s${RESET}"
    sleep "$delay"
    attempt=$((attempt + 1))
  done

  return 1
}

# Wait for a k8s condition with timeout
wait_for() {
  local description="$1"
  local timeout="$2"
  shift 2
  local cmd=("$@")
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    if "${cmd[@]}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  return 1
}

# Get app URL from LoadBalancer
get_app_url() {
  local url
  url=$(kubectl get svc resume-service -n "$APP_NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  echo "http://${url}"
}

# Get RDS endpoint from AWS
get_rds_endpoint() {
  aws rds describe-db-instances \
    --region "$AWS_REGION" \
    --db-instance-identifier "${PROJECT_NAME}-dev-postgres" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text 2>/dev/null
}

# Get DB password from Secrets Manager
get_db_password() {
  aws secretsmanager get-secret-value \
    --secret-id "${PROJECT_NAME}/dev/database" \
    --region "$AWS_REGION" \
    --query SecretString --output text 2>/dev/null | jq -r .password
}

# Send a test notification via curl
check_url() {
  local url="$1"
  local timeout="${2:-10}"
  curl -s --max-time "$timeout" -o /dev/null -w "%{http_code}" "$url"
}

# Load environment variables
load_env() {
  local env_file="$1"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

# Confirm action
confirm() {
  local message="$1"
  read -r -p "$(echo "${YELLOW}${message} [y/N]: ${RESET}")" response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}