#!/bin/bash
# Logging utilities

LOG_DIR="${LOG_DIR:-/tmp/ai-resume-analyzer-logs}"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/devops-$(date +%Y%m%d-%H%M%S).log"

log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

  case "$level" in
    ERROR)   print_error "$message" ;;
    WARN)    print_warn "$message" ;;
    SUCCESS) print_success "$message" ;;
    INFO)    print_info "$message" ;;
    STEP)    print_step "$message" ;;
    *)       echo "$message" ;;
  esac
}

log_file_location() {
  echo "${DIM}Log file: $LOG_FILE${RESET}"
}

fail() {
  log ERROR "$1"
  log_file_location
  exit 1
}