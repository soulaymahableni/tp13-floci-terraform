locals {
  prefix = "tp13"
}

# ---------- SQS : file principale + file de lettres mortes (DLQ) ----------
resource "aws_sqs_queue" "events_dlq" {
  name                      = "${local.prefix}-events-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 jours pour analyser les échecs
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "events" {
  name                       = "${local.prefix}-events-${var.environment}"
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = 30
  sqs_managed_sse_enabled    = true

  # Après 3 lectures sans suppression, le message part dans la DLQ.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 3
  })
}

# ---------- DynamoDB ----------
resource "aws_dynamodb_table" "visits" {
  #checkov:skip=CKV_AWS_28:PITR non nécessaire sur l'émulateur local
  #checkov:skip=CKV_AWS_119:Pas de KMS client (CMK) dans le lab Floci
  #checkov:skip=CKV2_AWS_16:Auto scaling inutile en mode PAY_PER_REQUEST
  name         = "${local.prefix}-visits-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# ---------- Secrets Manager ----------
resource "aws_secretsmanager_secret" "api_key" {
  #checkov:skip=CKV2_AWS_57:Pas de rotation automatique dans le lab
  #checkov:skip=CKV_AWS_149:Pas de KMS client (CMK) dans le lab Floci
  name                    = "${local.prefix}/${var.environment}/api-key"
  description             = "Clé API de démonstration TP13"
  recovery_window_in_days = 0 # suppression immédiate au destroy (lab)
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key
}
