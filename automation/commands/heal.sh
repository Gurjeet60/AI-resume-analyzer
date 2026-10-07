#!/bin/bash
# Self-healing automation — detects and fixes common issues

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

heal() {
  print_header "🔧 Auto-Healing Mode"

  local issues_found=0
  local issues_fixed=0

  # ---------- Check 1: Pods not running ----------
  print_section "Check 1 — Pod health"
  local bad_pods
  bad_pods=$(kubectl get pods -n "$APP_NAMESPACE" --no-headers 2>/dev/null | grep -vE "Running|Completed")

  if [ -n "$bad_pods" ]; then
    issues_found=$((issues_found + 1))
    print_warn "Unhealthy pods detected:"
    echo "$bad_pods" | awk '{print "  → " $1 " (" $3 ")"}'

    # Check for InvalidImageName
    if echo "$bad_pods" | grep -q "InvalidImageName"; then
      print_step "Fixing InvalidImageName (pods using _placeholder images)..."
      local backend_sha frontend_sha
      backend_sha=$(aws ecr describe-images \
        --repository-name "${PROJECT_NAME}-backend" --region "$AWS_REGION" \
        --query 'sort_by(imageDetails[?imageTags != null && length(imageTags) > `0`], &imagePushedAt)[-1].imageTags[0]' \
        --output text 2>/dev/null)

      frontend_sha=$(aws ecr describe-images \
        --repository-name "${PROJECT_NAME}-frontend" --region "$AWS_REGION" \
        --query 'sort_by(imageDetails[?imageTags != null && length(imageTags) > `0`], &imagePushedAt)[-1].imageTags[0]' \
        --output text 2>/dev/null)

      kubectl set image deployment/resume-backend -n "$APP_NAMESPACE" \
        backend="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:${backend_sha}" 2>/dev/null

      kubectl set image deployment/resume-app -n "$APP_NAMESPACE" \
        resume-app="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:${frontend_sha}" 2>/dev/null

      # Delete broken ReplicaSets
      kubectl get rs -n "$APP_NAMESPACE" --no-headers | awk '$3==0 {print $1}' | \
        xargs -r kubectl delete rs -n "$APP_NAMESPACE" --ignore-not-found >/dev/null

      issues_fixed=$((issues_fixed + 1))
      print_success "Fixed image name issue"
    fi

    # Check for CrashLoopBackOff → restart
    if echo "$bad_pods" | grep -q "CrashLoopBackOff"; then
      print_step "Deleting CrashLoopBackOff pods to force restart..."
      echo "$bad_pods" | grep "CrashLoopBackOff" | awk '{print $1}' | \
        xargs -r kubectl delete pod -n "$APP_NAMESPACE" --force --grace-period=0 >/dev/null
      issues_fixed=$((issues_fixed + 1))
      print_success "Restarted crashed pods"
    fi
  else
    print_success "All pods healthy"
  fi

  # ---------- Check 2: HPA not reading metrics ----------
  print_section "Check 2 — HPA metrics"
  local hpa_targets
  hpa_targets=$(kubectl get hpa -n "$APP_NAMESPACE" --no-headers 2>/dev/null | grep "<unknown>")

  if [ -n "$hpa_targets" ]; then
    issues_found=$((issues_found + 1))
    print_warn "HPA cannot read metrics — checking Metrics Server..."
    if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
      print_step "Installing Metrics Server..."
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null
      kubectl -n kube-system patch deployment metrics-server --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' >/dev/null
      issues_fixed=$((issues_fixed + 1))
      print_success "Metrics Server installed"
    else
      print_step "Restarting Metrics Server..."
      kubectl rollout restart deployment metrics-server -n kube-system >/dev/null
      issues_fixed=$((issues_fixed + 1))
      print_success "Metrics Server restarted"
    fi
  else
    print_success "HPA metrics working"
  fi

  # ---------- Check 3: NLB target health ----------
  print_section "Check 3 — NLB target health"
  local lb_arn
  lb_arn=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
    --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-resume`)].LoadBalancerArn' \
    --output text 2>/dev/null | head -1)

  if [ -n "$lb_arn" ]; then
    local tg_arn
    tg_arn=$(aws elbv2 describe-target-groups --region "$AWS_REGION" \
      --load-balancer-arn "$lb_arn" \
      --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

    if [ -n "$tg_arn" ]; then
      local target_count
      target_count=$(aws elbv2 describe-target-health --region "$AWS_REGION" \
        --target-group-arn "$tg_arn" \
        --query 'length(TargetHealthDescriptions)' --output text 2>/dev/null)

      if [ "$target_count" = "0" ]; then
        issues_found=$((issues_found + 1))
        print_warn "No targets registered with NLB — attempting re-registration"

        local node_id
        node_id=$(aws ec2 describe-instances --region "$AWS_REGION" \
          --filters "Name=tag:eks:nodegroup-name,Values=${NODEGROUP_NAME}" \
                    "Name=instance-state-name,Values=running" \
          --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)

        if [ -n "$node_id" ] && [ "$node_id" != "None" ]; then
          local node_port
          node_port=$(kubectl get svc resume-service -n "$APP_NAMESPACE" \
            -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

          aws elbv2 register-targets --region "$AWS_REGION" \
            --target-group-arn "$tg_arn" \
            --targets "Id=${node_id},Port=${node_port}" >/dev/null 2>&1

          issues_fixed=$((issues_fixed + 1))
          print_success "Re-registered target: $node_id"
        fi
      else
        print_success "NLB has $target_count healthy targets"
      fi
    fi
  fi

  # ---------- Check 4: Node pod capacity ----------
  print_section "Check 4 — Node capacity"
  local max_pods
  max_pods=$(kubectl get node -o jsonpath='{.items[0].status.capacity.pods}' 2>/dev/null)
  if [ "$max_pods" -lt 110 ]; then
    print_warn "Node pod capacity is $max_pods (expected 110+)"
    print_info "Fix: recycle node to pick up launch template"
  else
    print_success "Node capacity: $max_pods pods"
  fi

  # ---------- Check 5: Old ReplicaSets ----------
  print_section "Check 5 — Old ReplicaSets cleanup"
  local old_rs
  old_rs=$(kubectl get rs -n "$APP_NAMESPACE" --no-headers 2>/dev/null | awk '$2==0 && $3==0' | wc -l)
  if [ "$old_rs" -gt 5 ]; then
    print_step "Cleaning $old_rs old ReplicaSets..."
    kubectl get rs -n "$APP_NAMESPACE" --no-headers | awk '$2==0 && $3==0 {print $1}' | \
      xargs -r kubectl delete rs -n "$APP_NAMESPACE" >/dev/null
    issues_fixed=$((issues_fixed + 1))
    print_success "Cleaned up old ReplicaSets"
  else
    print_success "ReplicaSet count is healthy"
  fi

  # ---------- Summary ----------
  print_header "Healing Summary"
  echo "  Issues found:  $issues_found"
  echo "  Issues fixed:  $issues_fixed"
  echo ""

  if [ "$issues_found" -eq 0 ]; then
    print_success "Everything is healthy!"
  fi
}