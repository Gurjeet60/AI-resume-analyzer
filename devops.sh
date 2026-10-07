#!/bin/bash
#
# AI Resume Analyzer — One-Click DevOps Automation
#
# Usage:
#   ./devops.sh bootstrap      First-time full setup
#   ./devops.sh deploy         Deploy application updates
#   ./devops.sh status         Health dashboard
#   ./devops.sh heal           Auto-detect and fix issues
#   ./devops.sh logs           View logs
#   ./devops.sh cost           Cost analysis
#   ./devops.sh destroy        Tear down everything
#   ./devops.sh help           Show help
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$SCRIPT_DIR/automation"

# Source common libs
source "$AUTOMATION_DIR/lib/utils.sh"
source "$AUTOMATION_DIR/lib/checks.sh"

# Show banner
show_banner() {
  cat <<'EOF'

  ╔══════════════════════════════════════════════════════════╗
  ║                                                          ║
  ║   🚀  AI RESUME ANALYZER — DevOps Automation            ║
  ║                                                          ║
  ║   One script to provision, deploy, monitor, and heal    ║
  ║                                                          ║
  ╚══════════════════════════════════════════════════════════╝

EOF
}

# Show help
show_help() {
  show_banner
  cat <<EOF
${BOLD}USAGE:${RESET}
  ./devops.sh <command> [options]

${BOLD}COMMANDS:${RESET}
  ${GREEN}bootstrap${RESET}     Provision everything from scratch (30-40 min)
  ${GREEN}deploy${RESET}        Build, push, and deploy new application version
  ${GREEN}status${RESET}        Show complete health dashboard
  ${GREEN}heal${RESET}          Auto-detect and fix common issues
  ${GREEN}logs${RESET} [target]  View logs (target: app | monitoring)
  ${GREEN}cost${RESET}          Show AWS cost analysis
  ${GREEN}destroy${RESET}       Destroy all infrastructure (careful!)
  ${GREEN}help${RESET}          Show this help

${BOLD}EXAMPLES:${RESET}
  ./devops.sh bootstrap           # First-time setup
  ./devops.sh status              # Check project health
  ./devops.sh heal                # Fix common issues
  ./devops.sh logs app            # Tail application logs
  ./devops.sh cost                # Check AWS spending

EOF
}

# Main dispatch
main() {
  local command="${1:-help}"

  case "$command" in
    bootstrap)
      source "$AUTOMATION_DIR/commands/bootstrap.sh"
      bootstrap
      ;;
    deploy)
      source "$AUTOMATION_DIR/commands/deploy.sh"
      deploy
      ;;
    status)
      source "$AUTOMATION_DIR/commands/status.sh"
      status
      ;;
    heal)
      source "$AUTOMATION_DIR/commands/heal.sh"
      heal
      ;;
    logs)
      source "$AUTOMATION_DIR/commands/logs.sh"
      logs "$2"
      ;;
    cost)
      source "$AUTOMATION_DIR/commands/cost.sh"
      cost
      ;;
    destroy)
      source "$AUTOMATION_DIR/commands/destroy.sh"
      destroy
      ;;
    help|--help|-h|"")
      show_help
      ;;
    *)
      print_error "Unknown command: $command"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"