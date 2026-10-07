#!/bin/bash
# Unified logs viewer

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

logs() {
  local target="${1:-app}"

  case "$target" in
    app|frontend|backend)
      print_header "${GEAR} Application Logs"
      echo "  [1] Frontend"
      echo "  [2] Backend"
      echo "  [3] Both (follow)"
      echo ""
      read -r -p "Choose: " choice
      case "$choice" in
        1) kubectl logs -n "$APP_NAMESPACE" -l app=resume-app --tail=100 -f ;;
        2) kubectl logs -n "$APP_NAMESPACE" -l app=resume-backend --tail=100 -f ;;
        3)
          kubectl logs -n "$APP_NAMESPACE" -l app=resume-app --tail=50 -f &
          kubectl logs -n "$APP_NAMESPACE" -l app=resume-backend --tail=50 -f
          ;;
      esac
      ;;
    monitoring|prometheus|grafana)
      print_header "${GEAR} Monitoring Logs"
      echo "  [1] Prometheus"
      echo "  [2] Grafana"
      echo "  [3] Operator"
      echo ""
      read -r -p "Choose: " choice
      case "$choice" in
        1) kubectl logs -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=prometheus --tail=100 -f ;;
        2) kubectl logs -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=grafana -c grafana --tail=100 -f ;;
        3) kubectl logs -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=kube-prometheus-stack-prometheus-operator --tail=100 -f ;;
      esac
      ;;
    *)
      echo "Usage: ./devops.sh logs [app|monitoring]"
      ;;
  esac
}