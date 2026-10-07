#!/bin/bash
# Cost analysis

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

cost() {
  print_header "${MONEY} AWS Cost Analysis"

  # Current month
  print_section "Current Month (Month to Date)"
  local start end
  start=$(date +%Y-%m-01)
  end=$(date -d 'tomorrow' +%Y-%m-%d)

  aws ce get-cost-and-usage \
    --time-period "Start=$start,End=$end" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --output table 2>/dev/null | head -40

  # Last 7 days
  print_section "Last 7 Days (Daily Trend)"
  local w_start
  w_start=$(date -d '7 days ago' +%Y-%m-%d)

  aws ce get-cost-and-usage \
    --time-period "Start=$w_start,End=$end" \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --output table 2>/dev/null | head -30

  # Forecast
  print_section "Forecast for Current Month"
  local f_end
  f_end=$(date -d "$(date +%Y-%m-01) +1 month" +%Y-%m-01)

  aws ce get-cost-forecast \
    --time-period "Start=$start,End=$f_end" \
    --metric UNBLENDED_COST \
    --granularity MONTHLY \
    --output json 2>/dev/null | jq -r '"  Forecasted: $" + (.Total.Amount | tonumber | . * 100 | round / 100 | tostring)'

  # Idle resources
  print_section "Idle Resource Audit"

  local ebs_count eip_count
  ebs_count=$(aws ec2 describe-volumes --region "$AWS_REGION" \
    --filters "Name=status,Values=available" \
    --query 'length(Volumes)' --output text 2>/dev/null)
  eip_count=$(aws ec2 describe-addresses --region "$AWS_REGION" \
    --query 'length(Addresses[?AssociationId==null])' --output text 2>/dev/null)

  echo "  Unattached EBS volumes:  $ebs_count"
  echo "  Unassociated Elastic IPs: $eip_count"
  echo ""

  if [ "$ebs_count" = "0" ] && [ "$eip_count" = "0" ]; then
    print_success "No idle resources detected"
  else
    print_warn "Idle resources found — review in AWS console"
  fi

  # EKS support type
  print_section "EKS Cost Impact"
  local eks_version eks_support
  eks_version=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
    --query 'cluster.version' --output text 2>/dev/null)
  eks_support=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
    --query 'cluster.upgradePolicy.supportType' --output text 2>/dev/null)

  echo "  EKS Version:  $eks_version"
  echo "  Support Type: $eks_support"
  echo ""

  if [ "$eks_support" = "STANDARD" ]; then
    print_success "Standard support — cost optimized"
  else
    print_warn "EXTENDED support — upgrade cluster to save ~6x cost"
  fi
}