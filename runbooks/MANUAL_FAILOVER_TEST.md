# MANUAL_FAILOVER_TEST

Procedure to test failover:
1. Mark primary instance as unhealthy (stop VPN service or simulate health script returning 0).
2. Ensure CloudWatch alarm would trip (or trigger Lambda manually with test event).
3. Verify Route53 record updates to standby IP.
4. Confirm client reconnect behavior and document RTO.
