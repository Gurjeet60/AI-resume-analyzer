#!/bin/bash
# Deploy/update the application

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

deploy() {
  print_header "${ROCKET} Deploy Application"

  # Build and push images (assuming Dockerfile at root)
  print_section "Building and pushing Docker images"

  # Get ECR credentials
  aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin \
    "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" >/dev/null 2>&1 || \
    fail "ECR login failed"

  local git_sha
  git_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "$(date +%s)")

  # Build + push backend
  print_step "Building backend..."
  docker buildx build --platform linux/amd64,linux/arm64 \
    -t "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:${git_sha}" \
    --push ./backend >/dev/null || fail "Backend build failed"

  # Build + push frontend
  print_step "Building frontend..."
  docker buildx build --platform linux/amd64,linux/arm64 \
    -t "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:${git_sha}" \
    --push ./frontend >/dev/null || fail "Frontend build failed"

  print_success "Images pushed with tag: $git_sha"

  # Apply manifests via kustomize
  print_section "Applying Kubernetes manifests"

  kubectl apply -k k8s/ >/dev/null 2>&1 || true

  kubectl set image deployment/resume-backend -n "$APP_NAMESPACE" \
    backend="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:${git_sha}"

  kubectl set image deployment/resume-app -n "$APP_NAMESPACE" \
    resume-app="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:${git_sha}"

  print_info "Waiting for rollout..."
  kubectl rollout status deployment/resume-app -n "$APP_NAMESPACE" --timeout=180s || fail "Frontend rollout failed"
  kubectl rollout status deployment/resume-backend -n "$APP_NAMESPACE" --timeout=180s || fail "Backend rollout failed"

  print_success "Deployment complete"
}