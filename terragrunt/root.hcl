# DÉFI Terragrunt : configuration racine partagée par dev / staging / prod.
# (Les versions récentes de Terragrunt recommandent root.hcl plutôt qu'un
#  terragrunt.hcl à la racine ; le principe est identique.)
# Usage : cd terragrunt/dev && terragrunt plan
# Prérequis : buckets.tf = version modules (Partie 4) et TF_VAR_api_key exporté.

locals {
  environment = basename(get_terragrunt_dir())
}

terraform {
  source = "${get_repo_root()}/terraform"
}

# Génère backend.tf avec une clé de state par environnement
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-HCL
    terraform {
      backend "s3" {
        bucket                      = "tp13-tfstate"
        key                         = "terragrunt/${local.environment}/terraform.tfstate"
        region                      = "us-east-1"
        profile                     = "floci"
        encrypt                     = true
        use_lockfile                = true
        endpoints                   = { s3 = "http://localhost:4566" }
        use_path_style              = true
        skip_credentials_validation = true
        skip_metadata_api_check     = true
        skip_requesting_account_id  = true
        skip_region_validation      = true
      }
    }
  HCL
}

inputs = {
  environment = local.environment
}
