# Seeded misconfiguration (§6) — 0.0.0.0/0 ingress on port 22.
resource "aws_security_group" "app_sg" {
  name        = "orca-poc-target-sg"
  description = "Security group for the demo app tier"

  ingress {
    description = "SSH from anywhere (seeded misconfiguration)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
