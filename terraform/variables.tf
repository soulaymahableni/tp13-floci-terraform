variable "environment" {
  description = "Environnement cible"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit valoir dev, staging ou prod."
  }
}

variable "region" {
  description = "Région AWS simulée"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Profil AWS CLI contenant les identifiants fictifs"
  type        = string
  default     = "floci"
}

variable "floci_endpoint" {
  description = "Endpoint de l'émulateur Floci"
  type        = string
  default     = "http://localhost:4566"
}

variable "message_retention_seconds" {
  description = "Durée de rétention des messages SQS"
  type        = number
  default     = 86400
}

variable "api_key" {
  description = "Valeur du secret API (à passer via TF_VAR_api_key, jamais dans un .tfvars)"
  type        = string
  sensitive   = true
}
