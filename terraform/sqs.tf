resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"

  message_retention_seconds = 1209600

  sqs_managed_sse_enabled = true

  tags = local.common_tags
}

resource "aws_sqs_queue" "image_processing" {
  name = "${var.project_name}-queue"

  visibility_timeout_seconds = 180

  message_retention_seconds = 345600

  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.common_tags
}
data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.image_processing.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_s3_bucket.source.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "image_processing" {
  queue_url = aws_sqs_queue.image_processing.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}