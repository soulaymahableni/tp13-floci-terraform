# State distant dans S3 (Floci) avec verrou natif S3 (use_lockfile, Terraform >= 1.10).
# Bootstrap préalable : ../scripts/bootstrap-backend.sh
# Puis : mv backend.tf.example backend.tf && terraform init -migrate-state

terraform {
  backend "s3" {
    bucket  = "tp13-tfstate"
    key     = "envs/dev/terraform.tfstate"
    region  = "us-east-1"
    profile = "floci"
    encrypt = true

    # Verrou : fichier .tflock créé par écriture conditionnelle S3
    use_lockfile = true

    endpoints = {
      s3 = "http://localhost:4566"
    }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
  }
}
