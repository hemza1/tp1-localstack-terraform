# ==============================
# Configuration Terraform
# ==============================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==============================
# Variables d'entrée (Étape 3.1 + extras)
# ==============================
variable "region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "tp1"
}

variable "enable_versioning" {
  description = "Activer le versioning S3 sur le bucket principal"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Activer l'encryption S3 (non utilisée pour l'instant)"
  type        = bool
  default     = false
}

# ==============================
# Locals (variables dérivées)
# ==============================
locals {
  # Préfix commun pour nommer les buckets : tp1-dev
  bucket_prefix = "${var.project_name}-${var.environment}"

  # Tags communs à toutes les ressources (Étape 3.4)
  common_tags = {
    Name        = "Mon premier bucket"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }

  # Suffixes pour les buckets supplémentaires
  bucket_names = ["data", "logs", "backups"]
}

# ==============================
# Provider AWS pointant sur LocalStack (Étape 3.1)
# ==============================
provider "aws" {
  region     = var.region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3     = "http://localhost:4566"
    iam    = "http://localhost:4566"
    lambda = "http://localhost:4566"
  }

  s3_use_path_style = true
}

# ==============================
# Bucket S3 principal (Étape 3.1 + 3.4)
# ==============================
resource "aws_s3_bucket" "mon_premier_bucket" {
  # Nouveau nom basé sur les variables
  bucket = "${var.project_name}-bucket-${var.environment}"

  tags = local.common_tags
}

# ==============================
# Versioning S3 (Étape 3.3, piloté par enable_versioning)
# ==============================
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.mon_premier_bucket.id

  versioning_configuration {
    # Enabled / Suspended selon la variable
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ==============================
# Objet dans le bucket principal
# ==============================
resource "aws_s3_object" "fichier_hello" {
  bucket  = aws_s3_bucket.mon_premier_bucket.id
  key     = "hello.txt"
  content = "Hello from Terraform!"
}

# ==============================
# Bucket supplémentaire utilisant les locals
# ==============================
resource "aws_s3_bucket" "with_locals" {
  bucket = "${local.bucket_prefix}-example"

  tags = local.common_tags
}

# ==============================
# Plusieurs buckets créés via for_each
# ==============================
resource "aws_s3_bucket" "multi_buckets" {
  for_each = toset(local.bucket_names)

  bucket = "${local.bucket_prefix}-${each.key}"

  tags = merge(local.common_tags, {
    Purpose = each.key
  })
}

# ==============================
# Data source + Outputs (Étape 3.2)
# ==============================

# Région actuelle (via provider / LocalStack)
data "aws_region" "current" {}

output "current_region" {
  description = "Région actuelle"
  value       = data.aws_region.current.name
}

output "bucket_name" {
  description = "Nom du bucket S3 principal"
  value       = aws_s3_bucket.mon_premier_bucket.id
}

output "bucket_arn" {
  description = "ARN du bucket S3 principal"
  value       = aws_s3_bucket.mon_premier_bucket.arn
}
