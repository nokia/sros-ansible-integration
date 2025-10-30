#!/usr/bin/env bash
#
#    run.sh — Manage containerlab lifecycle and run categorized Ansible playbooks
#
#    Usage:
#      ./run.sh <command> [options]
#
#    Commands:
#      deploy      Deploy containerlab topology and run commission playbook
#      run         Run categorized playbooks
#      destroy     Destroy containerlab topology
#      sanity      Full sequence: deploy, run, destroy
#      help        Show this help message
#
#    Options:
#      -t, --topo <file>        Containerlab topology file (default: ./topo.clab.yml)
#      -p, --playbooks <file>   Playbook YAML inventory (default: ./playbooks.yml)
#      -c, --category <name>    Run only a specific category (default: all)
#      -q, --quiet              Suppress Ansible playbook logs
#      -a, --all                Run all tests aka continue on error
#
#    Example:
#      ./run.sh deploy
#      ./run.sh run --category all --quiet --all
#      ./run.sh destroy
#

set -euo pipefail

# --- Defaults ----------------------------------------------------------------

TOPOLOGY_FILE="./topo.clab.yml"
PLAYBOOK_FILE="./playbooks.yml"
CATEGORY=""
RUN_ALL=false
QUIET=false

# --- Logging -----------------------------------------------------------------

log() {
  local bold="\033[1m"
  local color_red="\033[31m"
  local color_green="\033[32m"
  local color_yellow="\033[33m"
  local reset="\033[0m"

  local level="$1"; shift
  local msg="$*"
  case "$level" in
    BOLD) echo -e "${bold}${color_yellow}[INFO]${reset} ${bold}$msg${reset}" ;;
    INFO) echo -e "${color_yellow}[INFO]${reset} $msg" ;;
    OK) echo -e "${color_green}[OK]${reset} $msg" ;;
    FAIL) echo -e "${color_red}[FAIL]${reset} $msg" ;;
    *) echo "$msg" ;;
  esac
}

# --- YAML Helpers ------------------------------------------------------------

yaml_categories() {
python3 - "$PLAYBOOK_FILE" << EOF
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
for c in data.get("categories", {}): print(c)
EOF
}

yaml_playbooks() {
python3 - "$PLAYBOOK_FILE" "$1" << EOF
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
cat = sys.argv[2]
for p in data.get("categories", {}).get(cat, {}).get("playbooks", []): print(p)
EOF
}

yaml_commission() {
python3 - "$PLAYBOOK_FILE" << EOF
import sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
print(data.get("commission", {}).get("playbook", "") or "")
EOF
}

# --- Containerlab Lifecycle --------------------------------------------------

start_lab() {
  log INFO "Deploying containerlab topology: $TOPOLOGY_FILE"
  sudo containerlab deploy -t "$TOPOLOGY_FILE" --reconfigure
  log OK "Containerlab deployed successfully"

  local commission_playbook
  commission_playbook=$(yaml_commission)

  if [[ -n "$commission_playbook" && -f "$commission_playbook" ]]; then
    log INFO "Running commission playbook: $commission_playbook"
    run_playbook "$commission_playbook"
  else
    log INFO "No commission playbook defined or not found"
  fi
}

stop_lab() {
  log INFO "Destroying containerlab topology"
  sudo containerlab destroy -t "$TOPOLOGY_FILE" || true
  log OK "Containerlab destroyed"
}

# --- Playbook Runner ---------------------------------------------------------

run_playbook() {
  local pb="${1:-}"
  local start_time=$(date +%s)

  # Execute quietly or verbosely
  set +e
  if $QUIET; then
    log INFO "Running: ansible-playbook $pb"
    ansible-playbook $pb >/dev/null 2>&1 || result=$?
  else
    log BOLD "Running: ansible-playbook $pb"
    ANSIBLE_FORCE_COLOR=true ansible-playbook $pb 2>&1 | sed 's/^/    /'
    result=${PIPESTATUS[0]}
  fi
  set -e

  local duration=$(( $(date +%s) - start_time ))

  if [[ ${result:-0} -eq 120 ]]; then
    log FAIL "Execution interrupted by user (Ctrl-C)"
    exit $result
  elif [[ ${result:-0} -ne 0 ]]; then
    log FAIL "$pb failed after ${duration}s"
    if ! $RUN_ALL; then
      # terminate script
      exit 1
    fi
  else
    log OK "$pb succeeded in ${duration}s"
  fi
}

# --- Test Orchestration ------------------------------------------------------

run_tests() {
  log INFO "Running playbooks from $PLAYBOOK_FILE"
  for cat in $(yaml_categories); do
    if [[ -n "$CATEGORY" && "$CATEGORY" != "all" && "$CATEGORY" != "$cat" ]]; then
      continue
    fi
    
    log INFO "=== CATEGORY: $cat ==="

    yaml_playbooks "$cat" | while IFS= read -r playbook; do    
      run_playbook "$playbook"
    done
  done
}

# --- Sanity Sequence ---------------------------------------------------------

sanity_run() {
  log INFO "Starting full sanity sequence"
  start_lab
  run_tests
  stop_lab
  log OK "Sanity sequence completed"
}

# --- CLI ---------------------------------------------------------------------

COMMAND="${1:-sanity}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--topo) TOPOLOGY_FILE="$2"; shift 2 ;;
    -p|--playbooks) PLAYBOOK_FILE="$2"; shift 2 ;;
    -c|--category) CATEGORY="$2"; shift 2 ;;
    -q|--quiet) QUIET=true; shift ;;
    -a|--all) RUN_ALL=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$COMMAND" in
  deploy) start_lab ;;
  run) run_tests ;;
  destroy) stop_lab ;;
  sanity) sanity_run ;;
  help) grep '^#  ' "$0" | sed 's/^# \{0,4\}//'; exit 0 ;;
  *) echo "Usage: $0 {deploy|run|destroy|sanity}"; exit 1 ;;
esac
