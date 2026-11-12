# PARTIE 4 : le bucket sécurisé passe dans un module, appelé deux fois.
# cp etapes/buckets-partie4.tf.example buckets.tf

module "uploads" {
  source      = "./modules/secure-bucket"
  bucket_name = "tp13-uploads-${var.environment}"
}

module "backups" {
  source      = "./modules/secure-bucket"
  bucket_name = "tp13-backups-${var.environment}"
}

# Les blocs moved indiquent à Terraform que les ressources ont seulement
# changé d'adresse : il les déplace dans le state au lieu de les détruire
# puis recréer. (Équivalent manuel : terraform state mv, voir README.)
moved {
  from = aws_s3_bucket.uploads
  to   = module.uploads.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.uploads
  to   = module.uploads.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_public_access_block.uploads
  to   = module.uploads.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.uploads
  to   = module.uploads.aws_s3_bucket_server_side_encryption_configuration.this
}

output "uploads_bucket" {
  value = module.uploads.bucket_id
}

output "backups_bucket" {
  value = module.backups.bucket_id
}
