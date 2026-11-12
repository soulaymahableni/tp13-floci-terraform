terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

# Provider AWS pointé sur Floci (http://localhost:4566).
# Les identifiants viennent du profil "floci" (test / test) : rien n'est écrit en dur.
provider "aws" {
  region  = var.region
  profile = var.aws_profile

  # Pas d'appel STS GetCallerIdentity pour valider les clés (fictives ici).
  skip_credentials_validation = true
  # Pas d'interrogation du service de métadonnées EC2 (169.254.169.254) : on n'est pas sur EC2.
  skip_metadata_api_check = true
  # Pas d'appel IAM/STS pour découvrir l'Account ID.
  skip_requesting_account_id = true
  # Accepte n'importe quel nom de région sans vérification.
  skip_region_validation = true

  # URL en "path style" : http://localhost:4566/<bucket> au lieu de
  # http://<bucket>.localhost:4566 (sous-domaine non résolu en local).
  s3_use_path_style = true

  # Chaque API AWS utilisée est redirigée vers Floci.
  endpoints {
    s3             = var.floci_endpoint
    sqs            = var.floci_endpoint
    dynamodb       = var.floci_endpoint
    secretsmanager = var.floci_endpoint
    lambda         = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
  }

  default_tags {
    tags = {
      Project     = "tp13"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
