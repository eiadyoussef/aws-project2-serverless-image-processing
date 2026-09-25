output "source_bucket" {
  value = aws_s3_bucket.source.bucket
}

output "processed_bucket" {
  value = aws_s3_bucket.processed.bucket
}

output "sqs_queue" {
  value = aws_sqs_queue.image_processing.name
}

output "dlq" {
  value = aws_sqs_queue.dlq.name
}

output "lambda_function" {
  value = aws_lambda_function.image_processor.function_name
}

output "dynamodb_table" {
  value = aws_dynamodb_table.image_metadata.name
}

