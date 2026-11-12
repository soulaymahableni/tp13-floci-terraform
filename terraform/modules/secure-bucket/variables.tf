variable "bucket_name" {
  description = "Nom du bucket S3"
  type        = string
}

variable "force_destroy" {
  description = "Autorise la suppression du bucket même s'il contient des objets (lab)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags supplémentaires"
  type        = map(string)
  default     = {}
}
