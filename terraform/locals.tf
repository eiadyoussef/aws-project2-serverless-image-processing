data "aws_caller_identity" "current" {}

locals {
  bucket_suffix = "${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  source_bucket_name    = "${var.project_name}-source-${local.bucket_suffix}"
  processed_bucket_name = "${var.project_name}-processed-${local.bucket_suffix}"

  common_tags = {
    Project     = "AWS-SAA-Project-2"
    Environment = "Graduation"
    ManagedBy   = "Terraform"
  }
}