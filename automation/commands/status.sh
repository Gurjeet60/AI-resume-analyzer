#!/bin/bash
# Health dashboard

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

status() {
  print_header "${CHART} Project Status Dashboard"

  # App URL
  local url
  url=$(get_app_url)
  echo "  ${BOLD}App URL:${RESET}  $url"
  echo ""

  # ---------- Application health ----------
  print_section "Application"
  if curl -sf --max-time 10 "$url/health" >/dev/null 2>&1; then
    print_success "Frontend: responding"
  else
    print_error "Frontend: DOWN"
  fi

  if curl -sf --max-time 10 "$url/api/health" >/dev/null 2>&1; then
    print_success "Backend:  responding"
  else
    print_error "Backend:  DOWN"
  fi
  echo ""

  # ---------- Pods ----------
  print_section "Kubernetes Pods"
  printf "  ${DIM}%-45s %-8s %-12s %s${RESET}\n" "NAME" "READY" "STATUS" "RESTARTS"
  kubectl get pods -n "$APP_NAMESPACE" --no-headers 2>/dev/null | \
    awk '{printf "  %-45s %-8s %-12s %s\n", $1, $2, $3, $4}'
  echo ""

  # ---------- HPA ----------
  print_section "Autoscaling (HPA)"
  kubectl get hpa -n "$APP_NAMESPACE" 2>/dev/null
  echo ""

  # ---------- Monitoring ----------
  print_section "Monitoring Stack"
  kubectl get pods -n "$MONITORING_NAMESPACE" --no-headers 2>/dev/null | \
    awk '{printf "  %-55s %-6s %s\n", $1, $2, $3}'
  echo ""

  # ---------- Nodes ----------
  print_section "Cluster Nodes"
  kubectl get nodes -o wide 2>/dev/null
  echo ""

  # ---------- Cluster Capacity ----------
  print_section "Capacity"
  local used max
  used=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
  max=$(kubectl get node -o jsonpath='{.items[0].status.capacity.pods}' 2>/dev/null)
  echo "  Pods used: $used / Max per node: $max"
  echo "  Nodes:     $(kubectl get nodes --no-headers 2>/dev/null | wc -l)"
  echo ""

  # ---------- Unhealthy pods ----------
  print_section "Unhealthy Pods"
  local unhealthy
  unhealthy=$(kubectl get pods -A --no-headers 2>/dev/null | grep -vE "Running|Completed" | grep -v "0/0")
  if [ -z "$unhealthy" ]; then
    print_success "All pods healthy"
  else
    echo "$unhealthy" | awk '{printf "  ${RED}%-45s %-25s %-15s %s${RESET}\n", $2, $1, $4, $5}'
  fi
  echo ""

  # ---------- EKS Version ----------
  print_section "EKS Info"
  local eks_version eks_support
  eks_version=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
    --query 'cluster.version' --output text 2>/dev/null)
  eks_support=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
    --query 'cluster.upgradePolicy.supportType' --output text 2>/dev/null)
  echo "  Version:      $eks_version"
  echo "  Support type: $eks_support"
  echo ""
}