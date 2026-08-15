# This repository is intentionally vulnerable. §6 of the build spec calls for disabling
# whichever tflint-ruleset-aws rules would fire on the seeded defects below, so CI reflects
# the customer's real posture (tests + syntax) rather than our own bait. Checked against the
# actual installed ruleset (tflint-ruleset-aws v0.36.0, docs enumerated directly from its
# GitHub repo): it has no rules for public S3 ACLs, open security-group ingress, or wildcard
# IAM actions at all — it's a deep AWS-API-validity linter (deprecated instance types,
# malformed ARNs, missing tags), not a security-posture scanner. There is therefore nothing
# to disable for:
#   - infra/terraform/s3.tf  (acl = "public-read")
#   - infra/terraform/sg.tf  (0.0.0.0/0 ingress)
#   - infra/iam/roles.tf     (wildcard IAM policy — bait)
# See DECISIONS.md for this finding. This file is kept (rather than deleted) so the aws
# plugin's real checks still run, and so a future contributor doesn't have to rediscover this.

plugin "aws" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
