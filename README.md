# 🔐 Fortifying Remote Access: High Availability Secure VPN Gateway

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A resilient, secure, and performant remote access solution built on AWS, engineered for exceptional uptime and fortified with Multi-Factor Authentication.

This repository documents the architecture, deployment, and operation of a **high-availability (HA) IPsec/OpenVPN cluster** on AWS. The solution is designed to provide secure, reliable, and performant remote workforce connectivity, featuring an automated failover mechanism triggered by proactive CloudWatch alarms.

This project showcases expertise in cloud networking, infrastructure security, high-availability systems, and automation.

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Deployment Instructions](#deployment-instructions)
- [Security Fortifications](#security-fortifications)
  - [Multi-Factor Authentication (MFA)](#multi-factor-authentication-mfa)
  - [Firewall & Security Groups](#firewall--security-groups)
- [High Availability & Automated Failover](#high-availability--automated-failover)
  - [Failover Mechanism](#failover-mechanism)
  - [Monitoring with CloudWatch](#monitoring-with-cloudwatch)
- [Performance Optimization](#performance-optimization)
- [Operational Runbooks](#operational-runbooks)
- [Repository Structure](#repository-structure)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

With the rise of remote work, providing secure and reliable access to private network resources is paramount. This project addresses this need by delivering a **zero-trust-aligned, highly available remote access layer** that protects corporate resources while ensuring employees can connect reliably, even during infrastructure disruptions.

The solution is designed with three core principles:
*   **Security:** Enforcing strong authentication and encrypting all traffic.
*   **Resilience:** Eliminating single points of failure and automating recovery.
*   **Performance:** Optimizing the network path for maximum throughput.

## Key Features

*   **High Availability:** Deployed as a multi-node cluster across multiple AWS Availability Zones (AZs) to eliminate single points of failure.
*   **Automated Failover:** A custom failover mechanism, triggered by proactive AWS CloudWatch alarms, ensures seamless service continuity with minimal downtime.
*   **Robust Security:** Hardened with mandatory Multi-Factor Authentication (MFA) for all user connections.
*   **Dual-Protocol Support:** Offers both **IPsec (strongSwan)** and **OpenVPN** to support a wide range of client devices and use cases.
*   **Optimized Throughput:** The infrastructure and VPN server configurations are meticulously tuned for high-performance network traffic.
*   **Infrastructure as Code (IaC):** The entire environment is defined in code (e.g., Terraform) for repeatable, consistent deployments.

## System Architecture

The architecture is designed for redundancy and automated recovery. Client traffic is directed to a stable endpoint (e.g., a Route 53 record), which points to the active VPN instance. CloudWatch continuously monitors the health of this instance. If a failure is detected, a Lambda function is triggered to automatically reroute traffic to the standby instance in another AZ.

```text
                                                                   +------------------+
                                                                   |   Corporate VPC  |
                                                                   |  (Private Subnet)|
                                                                   +--------+---------+
                                                                            |
                             +----------------------------------------------+---------------------------------+
                             |                                                                                |
               +-------------v-------------+                                                  +---------------v-------------+
               |   AWS Availability Zone A |                                                  |   AWS Availability Zone B   |
               |                           |                                                  |                             |
               |  +-------------------+    |                                                  |   +----------------------+  |
               |  |  [ACTIVE]         |    |                                                  |  |        [STANDBY]      |  |
               |  |  VPN Instance     +----+--------+-----------------------------------------|  |  VPN Instance         |  |
               |  |  (EC2: IPsec/OpenVPN)  |         |                         |              |  |  (EC2: IPsec/OpenVPN) |  |
               |  +-------------------+    |         |                         |              |  +-----------------------+  |
               |                           |         |                         |              |                             |
               +------------^--------------+         |                         |              +----------------^------------+
                            |                        |                         |                               |
                            |                        |                         |                   Route 53 Health Check
                            |                        |                         |
                            |  vpn.yourcompany.com (Route 53 Failover Record)  |
                            +------------------------|-------------------------+
                                                             |
                                                             | (Client Connection)
                                                             |
                                                    +--------v--------+
                                                    |  Remote Worker  |
                                                    +-----------------+

                                                         ⬇
                                               AWS CloudWatch Alarms
                                              (Instance Status, CPU, Custom Health Script)
                                                         ⬇
                                               AWS Lambda Failover Handler
                                                         ⬇
                                               Route 53 DNS Record Update Action
```

## Technology Stack

*   **Cloud Provider:** AWS (Amazon Web Services)
*   **Compute:** Amazon EC2 (Network Optimized Instances, e.g., `c5n.large`)
*   **Networking:** Amazon VPC, Subnets, Route 53 (for DNS Failover)
*   **VPN Software:** OpenVPN (Community Edition), strongSwan (for IPsec)
*   **Infrastructure as Code:** Terraform
*   **Monitoring & Alerting:** Amazon CloudWatch (Alarms, Logs, Metrics)
*   **Automation:** AWS Lambda (Python/Node.js), Bash Scripts
*   **Authentication:** Google Authenticator PAM

## Getting Started

This section guides you through deploying the HA VPN gateway in your own AWS account.

### Prerequisites

*   An AWS Account with appropriate IAM permissions (EC2, VPC, CloudWatch, Route 53, Lambda).
*   AWS CLI configured locally.
*   Terraform installed.
*   A registered domain name managed in a Route 53 Hosted Zone.
*   An SSH key pair created in your target AWS region.

### Deployment Instructions

The entire infrastructure is provisioned using Terraform to ensure repeatability.

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/<your-github-username>/<your-repository-name>.git
    cd <your-repository-name>
    ```

2.  **Configure Infrastructure Variables:**
    Create a `terraform.tfvars` file and populate it with your specific values.
    ```hcl
    # Example terraform.tfvars

    aws_region     = "us-east-1"
    instance_type  = "c5n.large"
    key_name       = "<your-aws-ssh-key-name>"
    vpc_id         = "<your-vpc-id>"
    public_subnet_az1_id = "<your-public-subnet-id-in-az-a>"
    public_subnet_az2_id = "<your-public-subnet-id-in-az-b>"
    hosted_zone_id = "<your-route53-hosted-zone-id>"
    vpn_domain_name = "vpn.yourcompany.com"
    ```

3.  **Deploy the Stack:**
    Initialize Terraform, review the plan, and apply the changes.
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```
    This will provision the VPC components, EC2 instances, IAM roles, security groups, and CloudWatch alarms. The instance user data scripts will handle the installation and initial configuration of OpenVPN and strongSwan.

## Security Fortifications

### Multi-Factor Authentication (MFA)

To fortify security, MFA is enforced for all VPN connections. This project uses the Google Authenticator PAM module with FreeRADIUS.

*   **Setup:** The configuration involves installing the libpam-google-authenticator library on the RADIUS server, creating a dedicated PAM service profile for FreeRADIUS, and configuring FreeRADIUS to use this profile for authentication. The OpenVPN server is then configured with a RADIUS plugin to delegate all user authentication requests to the now MFA-enabled FreeRADIUS server.
*   **User Experience:** When connecting, users must provide their password and a time-based one-time password (TOTP) from their authenticator app.

### Firewall & Security Groups

AWS Security Groups act as a stateful firewall, configured with a least-privilege policy. Only traffic on the necessary ports is allowed:
*   **Port `1194/UDP`:** For OpenVPN traffic.
*   **Port `500/UDP` & `4500/UDP`:** For IPsec (IKEv2) traffic.
*   **Port `22/TCP`:** For SSH management (restricted to a specific bastion host or corporate IP).

## High Availability & Automated Failover

### Failover Mechanism

The solution uses a **DNS-based failover** strategy managed by Route 53, CloudWatch, and Lambda.

1.  **Health Checks:** Route 53 performs regular health checks on the primary (active) VPN instance.
2.  **Alarm Trigger:** A CloudWatch Alarm monitors the status of these health checks. If the primary instance becomes unresponsive for a specified period, the alarm enters the `ALARM` state.
3.  **Automated Remediation:** The alarm is configured to trigger an AWS Lambda function.
4.  **DNS Rerouting:** The Lambda function executes a script that updates the Route 53 DNS record, changing the IP address from the failed primary instance to the healthy standby instance.
5.  **Seamless Transition:** VPN clients, configured to use the domain name (`vpn.yourcompany.com`), will automatically reconnect to the new active instance after a brief interruption.

### Monitoring with CloudWatch

The failover process is triggered by a combination of pre-configured CloudWatch alarms:
*   **Route 53 Health Check Status:** The primary trigger for failover.
*   **StatusCheckFailed:** Triggers if the instance fails its underlying system or instance status checks.
*   **High CPU Utilization:** An alarm to detect an overloaded or unresponsive server.
*   **Custom VPN Service Health Metric:** A custom script, executed via cron, runs every minute on each VPN instance. This script checks the status of the openvpn and strongswan service daemons. It then pushes a custom metric (e.g., VPNDaemonHealth, with a value of 1 for healthy or 0 for unhealthy) to CloudWatch. An alarm is configured to trigger if this metric reports 0 for several consecutive minutes, indicating a software-level failure that requires a failover.

## Performance Optimization

Several measures were taken to optimize network throughput:
*   **Instance Selection:** Chose EC2 instances from a network-optimized family (`c5n`, `m5n`) with high bandwidth capabilities.
*   **Kernel Tuning (`sysctl`):** Modified kernel parameters (`net.core.rmem_max`, `net.core.wmem_max`, etc.) on the Linux servers to increase network buffer sizes and improve performance under load.
*   **VPN Protocol Settings:**
    *   For OpenVPN, **UDP** is used over TCP for lower overhead and better performance.
    *   A modern, performant cipher like **AES-256-GCM** was chosen, as it offers an excellent balance of security and speed on hardware that supports AES-NI (standard on modern EC2 instances).

## Operational Runbooks

To ensure the system can be managed effectively, operational guides are included in the `/runbooks` directory.
*   `runbooks/USER_ONBOARDING.md`: Step-by-step guide for enrolling new users and setting up their MFA.
*   `runbooks/MANUAL_FAILOVER_TEST.md`: Procedure for simulating an AZ failure to validate the automated recovery mechanism.
*   `runbooks/SYSTEM_RECOVERY.md`: Guide for restoring the primary node after a prolonged outage.

## Repository Structure

```
.
├── terraform/         # Terraform modules for all AWS resources
├── scripts/           # Bash scripts for server configuration and health checks
├── lambda/            # Python/Node.js code for the failover Lambda function
├── runbooks/          # Step-by-step operational guides (Markdown)
├── clients/           # Example OpenVPN/IPsec client configuration files
├── main.tf            # Root Terraform configuration file
├── variables.tf       # Terraform variable definitions
└── README.md          # This file
```

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.
