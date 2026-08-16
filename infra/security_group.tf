terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Fake, obviously-non-functional credentials: this sandbox never has real cloud
# access (01-AGENT-CARDS.md's A7 credential note), so `terraform plan -refresh=false`
# needs a provider config that never actually calls AWS. skip_credentials_validation
# / skip_requesting_account_id / skip_metadata_api_check make that possible entirely
# offline, against the checked-in infra/terraform.tfstate fixture below.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Deliberately misconfigured for the demo: SSH open to the entire internet.
# CKV_AWS_24 / aws-vpc-no-public-ingress-sgr. A7's fix narrows cidr_blocks to a
# VPC-scoped range — a pure attribute update, not a resource replacement.
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "demo"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
