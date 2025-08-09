#!/usr/bin/env bash
set -euo pipefail
# Run health_check in dry-run; expect exit 0 or 1 depending on systemd presence in CI.
./scripts/health_check.sh --dry-run
