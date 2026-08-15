# This repository is intentionally vulnerable. These rules are disabled so CI reflects the
# customer's real posture (tests + syntax), not our seeded bait (§6). Verify the actual rule
# names against the installed tflint-ruleset-aws version before relying on this in a live
# demo — the spec this repo was built from flags these names as indicative, not confirmed.

plugin "aws" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_s3_bucket_public_read_acl"      { enabled = false } # seeded: infra/terraform/s3.tf
rule "aws_security_group_invalid_ingress" { enabled = false } # seeded: infra/terraform/sg.tf
rule "aws_iam_policy_wildcard_actions"    { enabled = false } # seeded: infra/iam/roles.tf (bait)
