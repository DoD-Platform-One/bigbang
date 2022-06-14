variable "aws_region" {
  default = "us-gov-west-1"
}

variable "env" {}
variable "ci_pipeline_url" {}

variable "rke2_config" {
  type = string
  default = <<EOF
disable:
  - rke2-ingress-nginx
EOF
}