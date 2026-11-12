output "queue_url" {
  value = aws_sqs_queue.events.url
}

output "dlq_url" {
  value = aws_sqs_queue.events_dlq.url
}

output "dynamodb_table" {
  value = aws_dynamodb_table.visits.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.api_key.arn
}
