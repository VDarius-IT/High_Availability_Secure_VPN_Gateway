# Minimal Terraform root scaffolding (examples only)
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Example: VPC & two vpn instances (placeholder)
# Implement modules/vpn and modules/network for full production use.
