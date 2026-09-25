data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/image_processor/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "image_processor" {
  function_name = "${var.project_name}-processor"

  role = aws_iam_role.lambda_role.arn

  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  filename = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 60

  memory_size = 256

  environment {
    variables = {
      PROCESSED_BUCKET = aws_s3_bucket.processed.bucket
      TABLE_NAME       = aws_dynamodb_table.image_metadata.name
    }
  }

  tags = local.common_tags
}
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.image_processing.arn

  function_name = aws_lambda_function.image_processor.arn

  batch_size = 1

  enabled = true
}