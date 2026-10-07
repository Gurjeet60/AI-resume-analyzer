#!/bin/bash
# Pre-flight checks

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

check_prerequisites() {
  print_section "Checking prerequisites"

  local missing=()

  for tool in aws terraform kubectl helm docker jq curl; do
    if command_exists "$tool"; then
      print_success "$tool installed"
    else
      print_error "$tool NOT installed"
      missing+=("$tool")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    fail "Missing tools: ${missing[*]}. Install them first."
  fi
}

check_aws_auth() {
  print_section "Checking AWS authentication"

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    fail "AWS CLI not authenticated. Run 'aws configure' or 'aws sso login'."
  fi

  local account
  account=$(aws sts get-caller-identity --query Account --output text)
  print_success "AWS authenticated as account: $account"

  if [ "$account" != "$AWS_ACCOUNT_ID" ]; then
    print_warn "AWS account mismatch. Expected: $AWS_ACCOUNT_ID, Got: $account"
    confirm "Continue anyway?" || exit 1
  fi
}

check_terraform_state() {
  print_section "Checking Terraform state"

  local tf_dir="terraform/environments/dev"
  if [ ! -d "$tf_dir" ]; then
    fail "Terraform directory not found: $tf_dir"
  fi

  cd "$tf_dir" || fail "Cannot cd to $tf_dir"
  if [ ! -f "terraform.tfstate" ] && ! terraform state list >/dev/null 2>&1; then
    print_warn "No Terraform state found — will run init"
  else
    print_success "Terraform state exists"
  fi
  cd - >/dev/null || exit 1
}

check_cluster_access() {
  print_section "Checking EKS cluster access"

  if ! kubectl cluster-info >/dev/null 2>&1; then
    print_warn "No kubeconfig context — will be created during bootstrap"
    return 1
  fi

  local current_context
  current_context=$(kubectl config current-context 2>/dev/null)
  if [[ "$current_context" == *"$CLUSTER_NAME"* ]]; then
    print_success "Connected to cluster: $current_context"
    return 0
  else
    print_warn "Currently connected to: $current_context"
    return 1
  fi
}

run_all_checks() {
  check_prerequisites
  check_aws_auth
}