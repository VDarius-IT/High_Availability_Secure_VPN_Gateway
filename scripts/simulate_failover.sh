#!/usr/bin/env bash
set -euo pipefail

# Simulate failover by updating Route53 record to point to a standby IP.
# WARNING: This script will modify Route53 if run without editing placeholders.
# Usage: ./scripts/simulate_failover.sh --hosted-zone-id <ZONEID> --record vpn.example.com --ip <NEW_IP> [--dry-run]

DRY_RUN=false
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift;;
    --hosted-zone-id) HOSTED_ZONE_ID="$2"; shift 2;;
    --record) RECORD_NAME="$2"; shift 2;;
    --ip) NEW_IP="$2"; shift 2;;
    *) shift;;
  esac
done

if [ -z "${HOSTED_ZONE_ID:-}" ] || [ -z "${RECORD_NAME:-}" ] || [ -z "${NEW_IP:-}" ]; then
  echo "Usage: $0 --hosted-zone-id <ZONEID> --record <record-name> --ip <new-ip> [--dry-run]"
  exit 1
fi

change_batch=$(cat <<JSON
{
  "Comment": "Automated failover: point ${RECORD_NAME} to ${NEW_IP}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD_NAME}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{ "Value": "${NEW_IP}" }]
      }
    }
  ]
}
JSON
)

if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] Would call route53 change-resource-record-sets with:"
  echo "${change_batch}"
  exit 0
fi

aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --change-batch "${change_batch}"
