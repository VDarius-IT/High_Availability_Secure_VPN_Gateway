# SYSTEM_RECOVERY

Steps to recover primary node:
1. Investigate root cause and remediate.
2. Re-provision or repair primary EC2 instance.
3. Re-run userdata or configuration scripts to install VPN services.
4. Validate with health_check.sh and clear alarms.
5. Optional: fail back DNS when primary is fully healthy.
