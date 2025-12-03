# Configuration Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 🔹 Variables d'entrée utilisées par locals
variable "project_name" {
  type    = string
  default = "tp1-localstack"
}

variable "environment" {
  type    = string
  default = "dev"
}

# 🔹 Variables locales calculées
locals {
  bucket_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
  
  bucket_names = ["data", "logs", "backups"]
}

# Provider AWS configuré pour LocalStack
provider "aws" {
  region     = "us-east-1"
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

# Bucket S3 simple
resource "aws_s3_bucket" "mon_premier_bucket" {
  bucket = "tp1-bucket-test"

  # 🔹 On utilise les tags locaux ici
  tags = local.common_tags
}

# Fichier dans le bucket
resource "aws_s3_object" "fichier_hello" {
  bucket  = aws_s3_bucket.mon_premier_bucket.id
  key     = "hello.txt"
  content = "Hello from Terraform!"
}

# 🔹 Exemple d'utilisation de local.bucket_prefix
resource "aws_s3_bucket" "with_locals" {
  bucket = "${local.bucket_prefix}-example"

  tags = local.common_tags
}
