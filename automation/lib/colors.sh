#!/bin/bash
# Terminal colors and formatting

# Colors (only if stdout is a TTY)
if [ -t 1 ]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  MAGENTA=$'\033[0;35m'
  CYAN=$'\033[0;36m'
  WHITE=$'\033[1;37m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; WHITE=""; BOLD=""; DIM=""; RESET=""
fi

# Status symbols
CHECK="✅"
CROSS="❌"
WARN="⚠️ "
INFO="ℹ️ "
ROCKET="🚀"
GEAR="⚙️ "
HOURGLASS="⏳"
LOCK="🔒"
FIRE="🔥"
MONEY="💰"
CHART="📊"

# Header helper
print_header() {
  echo ""
  echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${CYAN}  $1${RESET}"
  echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
  echo ""
}

print_section() {
  echo ""
  echo "${BOLD}${BLUE}▶ $1${RESET}"
}

print_success() {
  echo "${GREEN}${CHECK} $1${RESET}"
}

print_error() {
  echo "${RED}${CROSS} $1${RESET}"
}

print_warn() {
  echo "${YELLOW}${WARN} $1${RESET}"
}

print_info() {
  echo "${BLUE}${INFO} $1${RESET}"
}

print_step() {
  echo "${MAGENTA}${GEAR} $1${RESET}"
}