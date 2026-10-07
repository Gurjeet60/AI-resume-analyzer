#!/bin/bash
# Teardown everything

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

destroy() {
  print_header "${FIRE} DESTROY MODE — This will delete EVERYTHING"

  confirm "Are you SURE you want to destroy all infrastructure?" || exit 0
  confirm "This will DELETE the EKS cluster, RDS database, and all data. Continue?" || exit 0

  # Remove LoadBalancer service first (to clean up NLB)
  print_section "Cleaning up LoadBalancer"
  kubectl delete svc resume-service -n "$APP_NAMESPACE" --ignore-not-found 2>/dev/null
  print_success "LoadBalancer service deleted"

  # Delete all helm releases
  print_section "Removing Helm releases"
  helm uninstall cluster-autoscaler-aws-cluster-autoscaler -n kube-system 2>/dev/null || true
  helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || true
  helm uninstall prometheus -n monitoring 2>/dev/null || true
  print_success "Helm releases removed"

  # Terraform destroy
  print_section "Destroying AWS infrastructure (15 min)"
  cd terraform/environments/dev || fail "Cannot cd"
  terraform destroy -auto-approve || fail "terraform destroy failed"
  cd - >/dev/null || exit 1

  print_header "${CHECK} Everything destroyed"
  print_info "Your AWS bill should stop growing immediately"
}