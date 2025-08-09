#!/usr/bin/env bash
set -euo pipefail

# Health check for VPN daemons (openvpn, strongswan)
# Usage:
#   ./scripts/health_check.sh [--dry-run] [--region REGION] [--namespace NAMESPACE] [--metric-name NAME] [--retries N] [--verbose]
#
# Exit codes:
#   0 = healthy (metric pushed if not dry-run)
#   1 = validation errors / detection indicates unhealthy daemons
#   2 = CloudWatch push failure
#   3 = unexpected error loading tools

DRY_RUN=false
AWS_REGION="${AWS_REGION:-us-east-1}"
METRIC_NAMESPACE="HA/VPN"
METRIC_NAME="VPNDaemonHealth"
RETRIES=1
VERBOSE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --region) shift; AWS_REGION="${1:-$AWS_REGION}"; shift ;;
    --namespace) shift; METRIC_NAMESPACE="${1:-$METRIC_NAMESPACE}"; shift ;;
    --metric-name) shift; METRIC_NAME="${1:-$METRIC_NAME}"; shift ;;
    --retries) shift; RETRIES="${1:-$RETRIES}"; shift ;;
    --verbose) VERBOSE=true; shift ;;
    *) echo "Unknown argument: $1"; exit 3 ;;
  esac
done

log() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Detect whether systemctl is available and running services, otherwise fallback to ps check
check_services() {
  # Prefer systemctl if present
  if command -v systemctl >/dev/null 2>&1; then
    log "$(timestamp) - Using systemctl to check service status"
    if systemctl is-active --quiet openvpn || systemctl is-active --quiet strongswan; then
      return 0
    else
      return 1
    fi
  fi

  # Fallback: check running processes (case-insensitive)
  log "$(timestamp) - systemctl not available; falling back to process check"
  if pgrep -f -i openvpn >/dev/null 2>&1 || pgrep -f -i strongswan >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

# Main
status_code=1
if check_services; then
  status_code=0
else
  status_code=1
fi

value=$(( status_code == 0 ? 1 : 0 ))
ts="$(timestamp)"

echo "[$ts] VPN health status: ${value} (0=bad,1=good)"

if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] Would put metric to CloudWatch: Namespace=${METRIC_NAMESPACE}, Metric=${METRIC_NAME}, Value=${value}, Region=${AWS_REGION}"
  exit $status_code
fi

# Ensure AWS CLI is available
if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI is not installed or not in PATH. Cannot push metric."
  exit 3
fi

# Push metric to CloudWatch with retries
attempt=0
while [ $attempt -lt "$RETRIES" ]; do
  attempt=$((attempt + 1))
  log "$(timestamp) - Putting metric attempt $attempt/${RETRIES} to CloudWatch (region=${AWS_REGION})"
  if aws cloudwatch put-metric-data --region "${AWS_REGION}" --namespace "${METRIC_NAMESPACE}" --metric-name "${METRIC_NAME}" --value "${value}" --unit Count >/dev/null 2>&1; then
    log "$(timestamp) - Successfully pushed metric to CloudWatch"
    exit $status_code
  else
    echo "$(timestamp) - Failed to push metric to CloudWatch (attempt $attempt)"
    # exponential backoff before retrying
    if [ $attempt -lt "$RETRIES" ]; then
      sleep_time=$((2 ** attempt))
      log "Sleeping ${sleep_time}s before retry"
      sleep $sleep_time
    fi
  fi
done

echo "$(timestamp) - All attempts to push metric failed. Ensure instance IAM role has cloudwatch:PutMetricData permission and AWS CLI is configured."
exit 2
