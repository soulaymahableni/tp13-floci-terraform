# Module : bucket S3 versionné, non public et chiffré.

resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:Pas de journalisation d'accès dans le lab
  #checkov:skip=CKV_AWS_144:Pas de réplication inter-régions dans le lab
  #checkov:skip=CKV_AWS_145:Chiffrement SSE-S3 (AES256), pas de KMS client sur Floci
  #checkov:skip=CKV2_AWS_61:Pas de règle de cycle de vie dans le lab
  #checkov:skip=CKV2_AWS_62:Pas de notifications d'événements dans le lab
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 (AES256) : pas de clé KMS client sur l'émulateur Floci
#trivy:ignore:AVD-AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
