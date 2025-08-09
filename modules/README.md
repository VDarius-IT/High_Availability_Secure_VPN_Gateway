Modules placeholder:
- modules/vpn : VPN EC2 instance(s) + userdata for OpenVPN/strongSwan
- modules/network : VPC, subnets, route53 health checks
- modules/lambda : Lambda failover code
Use these modules to split responsibilities; the terraform root references them.
