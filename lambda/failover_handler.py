"""
Example Lambda failover handler.

This is a template. The Lambda should be given a role allowing Route53 changes
and CloudWatch invocation permissions. It expects the event to contain the
standby IP and the record to update or can look up healthy instances.
"""
import json
import boto3
import os

route53 = boto3.client("route53")

def handler(event, context):
    # Example event:
    # {"hosted_zone_id": "Z123...", "record_name": "vpn.example.com.", "new_ip": "1.2.3.4"}
    hz = event.get("hosted_zone_id") or os.environ.get("HOSTED_ZONE_ID")
    record = event.get("record_name") or os.environ.get("RECORD_NAME")
    new_ip = event.get("new_ip")
    if not all([hz, record, new_ip]):
        return {"status": "error", "message": "missing parameters"}

    change_batch = {
        "Comment": "Automated failover",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": record,
                    "Type": "A",
                    "TTL": 60,
                    "ResourceRecords": [{"Value": new_ip}]
                }
            }
        ]
    }
    resp = route53.change_resource_record_sets(
        HostedZoneId=hz,
        ChangeBatch=change_batch
    )
    return {"status": "ok", "changeInfo": resp.get("ChangeInfo")}
