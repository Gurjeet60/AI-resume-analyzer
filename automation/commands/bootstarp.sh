#!/bin/bash
# Full bootstrap — provisions infrastructure + installs add-ons + deploys app

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/checks.sh"

bootstrap() {
  print_header "${ROCKET} Full Project Bootstrap"

  local start_time
  start_time=$(date +%s)

  # ---------- Phase 1: Pre-flight checks ----------
  run_all_checks

  # ---------- Phase 2: Terraform ----------
  bootstrap_terraform

  # ---------- Phase 3: kubeconfig ----------
  bootstrap_kubeconfig

  # ---------- Phase 4: Node group wait ----------
  bootstrap_wait_nodes

  # ---------- Phase 5: Cluster add-ons ----------
  bootstrap_addons

  # ---------- Phase 6: Monitoring stack ----------
  bootstrap_monitoring

  # ---------- Phase 7: Application deploy ----------
  bootstrap_app

  # ---------- Phase 8: Verify ----------
  bootstrap_verify

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  print_header "${CHECK} Bootstrap Complete in $((duration / 60))m $((duration % 60))s"

  local url
  url=$(get_app_url)
  echo "  ${BOLD}App URL:${RESET}     $url"
  echo "  ${BOLD}Grafana:${RESET}     kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
  echo "  ${BOLD}Prometheus:${RESET}  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
  echo ""
}

bootstrap_terraform() {
  print_section "Phase 1/7 — Provisioning AWS infrastructure with Terraform"
  print_info "This may take 15–20 minutes on first run..."

  cd terraform/environments/dev || fail "Cannot cd to terraform"

  if [ ! -d ".terraform" ]; then
    terraform init || fail "terraform init failed"
  fi

  terraform apply -auto-approve || fail "terraform apply failed"

  print_success "Infrastructure ready"
  cd - >/dev/null || exit 1
}

bootstrap_kubeconfig() {
  print_section "Phase 2/7 — Configuring kubectl"

  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME" >/dev/null || fail "kubeconfig update failed"

  print_success "kubectl configured for $CLUSTER_NAME"
}

bootstrap_wait_nodes() {
  print_section "Phase 3/7 — Waiting for worker nodes"

  local i=0
  local max=60
  while [ $i -lt $max ]; do
    local ready
    ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready ")
    if [ "$ready" -ge 1 ]; then
      print_success "$ready node(s) ready"
      return 0
    fi
    sleep 10
    i=$((i + 1))
  done

  fail "Nodes did not become Ready within 10 minutes"
}

bootstrap_addons() {
  print_section "Phase 4/7 — Installing cluster add-ons"

  # Metrics Server
  if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    print_step "Installing Metrics Server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null
    kubectl -n kube-system patch deployment metrics-server --type='json' \
      -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' >/dev/null
    print_success "Metrics Server installed"
  else
    print_success "Metrics Server already installed"
  fi

  # AWS Load Balancer Controller
  helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1
  helm repo update >/dev/null 2>&1

  if ! kubectl get sa aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
    print_step "Creating LB Controller service account..."
    kubectl create sa aws-load-balancer-controller -n kube-system >/dev/null
    kubectl annotate sa aws-load-balancer-controller -n kube-system \
      eks.amazonaws.com/role-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-alb-controller-role" \
      --overwrite >/dev/null
  fi

  if ! kubectl get deployment aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
    print_step "Installing AWS Load Balancer Controller..."
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName="$CLUSTER_NAME" \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set region="$AWS_REGION" >/dev/null
    print_success "AWS LB Controller installed"
  else
    print_success "AWS LB Controller already installed"
  fi

  # Cluster Autoscaler
  if ! kubectl get deployment cluster-autoscaler-aws-cluster-autoscaler-aws-cluster-autoscaler -n kube-system >/dev/null 2>&1; then
    print_step "Installing Cluster Autoscaler..."
    helm repo add autoscaler https://kubernetes.github.io/autoscaler >/dev/null 2>&1

    kubectl create sa cluster-autoscaler-aws-cluster-autoscaler -n kube-system >/dev/null 2>&1
    kubectl annotate sa cluster-autoscaler-aws-cluster-autoscaler -n kube-system \
      eks.amazonaws.com/role-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ClusterAutoscalerRole" \
      --overwrite >/dev/null

    helm upgrade --install cluster-autoscaler-aws-cluster-autoscaler autoscaler/cluster-autoscaler \
      -n kube-system \
      --version 9.46.6 \
      --set autoDiscovery.clusterName="$CLUSTER_NAME" \
      --set awsRegion="$AWS_REGION" \
      --set cloudProvider=aws \
      --set rbac.serviceAccount.create=false \
      --set rbac.serviceAccount.name=cluster-autoscaler-aws-cluster-autoscaler \
      --set extraArgs.balance-similar-node-groups=true >/dev/null
    print_success "Cluster Autoscaler installed"
  else
    print_success "Cluster Autoscaler already installed"
  fi
}

bootstrap_monitoring() {
  print_section "Phase 5/7 — Installing Prometheus + Grafana"

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1
  helm repo update >/dev/null 2>&1

  if ! helm list -n monitoring 2>/dev/null | grep -q "^prometheus"; then
    print_step "Installing kube-prometheus-stack (this takes ~5 min)..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
      -n monitoring --create-namespace \
      --set grafana.adminPassword=admin \
      --set grafana.resources.requests.memory=256Mi \
      --set grafana.resources.limits.memory=1Gi \
      --set prometheus.prometheusSpec.retention=2d \
      --set prometheus.prometheusSpec.resources.requests.memory=256Mi \
      --set prometheus.prometheusSpec.resources.limits.memory=512Mi \
      --set prometheusOperator.admissionWebhooks.enabled=false \
      --set prometheusOperator.admissionWebhooks.patch.enabled=false >/dev/null
    print_success "Monitoring stack installed"
  else
    print_success "Monitoring stack already installed"
  fi
}

bootstrap_app() {
  print_section "Phase 6/7 — Deploying application"

  # Get image SHAs from ECR
  local backend_sha frontend_sha
  backend_sha=$(aws ecr describe-images \
    --repository-name "${PROJECT_NAME}-backend" \
    --region "$AWS_REGION" \
    --query 'sort_by(imageDetails[?imageTags != null && length(imageTags) > `0`], &imagePushedAt)[-1].imageTags[0]' \
    --output text 2>/dev/null)

  frontend_sha=$(aws ecr describe-images \
    --repository-name "${PROJECT_NAME}-frontend" \
    --region "$AWS_REGION" \
    --query 'sort_by(imageDetails[?imageTags != null && length(imageTags) > `0`], &imagePushedAt)[-1].imageTags[0]' \
    --output text 2>/dev/null)

  if [ -z "$backend_sha" ] || [ "$backend_sha" = "None" ]; then
    print_warn "No tagged backend image in ECR — pipeline will build it on next push"
  else
    print_info "Backend image:  $backend_sha"
    print_info "Frontend image: $frontend_sha"

    # Set images via kubectl
    kubectl set image deployment/resume-backend -n "$APP_NAMESPACE" \
      backend="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:${backend_sha}" \
      2>/dev/null || true

    kubectl set image deployment/resume-app -n "$APP_NAMESPACE" \
      resume-app="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:${frontend_sha}" \
      2>/dev/null || true
  fi

  print_info "Waiting for rollout..."
  kubectl rollout status deployment/resume-app -n "$APP_NAMESPACE" --timeout=120s 2>/dev/null || true
  kubectl rollout status deployment/resume-backend -n "$APP_NAMESPACE" --timeout=120s 2>/dev/null || true

  print_success "Application deployed"
}

bootstrap_verify() {
  print_section "Phase 7/7 — Verifying deployment"

  # Wait for LoadBalancer
  print_info "Waiting for NLB provisioning (up to 3 min)..."
  local i=0
  while [ $i -lt 36 ]; do
    local hostname
    hostname=$(kubectl get svc resume-service -n "$APP_NAMESPACE" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$hostname" ]; then
      print_success "NLB ready: $hostname"
      break
    fi
    sleep 5
    i=$((i + 1))
  done

  # Health checks
  local url
  url=$(get_app_url)
  print_info "Testing endpoints..."

  if curl -sf --max-time 15 "$url/health" >/dev/null 2>&1; then
    print_success "Frontend: $url/health"
  else
    print_warn "Frontend not yet responding"
  fi

  if curl -sf --max-time 15 "$url/api/health" >/dev/null 2>&1; then
    print_success "Backend:  $url/api/health"
  else
    print_warn "Backend not yet responding"
  fi
}