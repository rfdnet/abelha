mm# Configuração do Provider AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Altere para sua região preferida
}

# Bucket S3 para hospedagem estática
resource "aws_s3_bucket" "reports_website" {
  bucket = "report1234-rdias"
}

# Configuração de hospedagem de website estático
resource "aws_s3_bucket_website_configuration" "reports_website" {
  bucket = aws_s3_bucket.reports_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Configuração de acesso público
resource "aws_s3_bucket_public_access_block" "reports_website" {
  bucket = aws_s3_bucket.reports_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política de bucket para permitir acesso público de leitura
resource "aws_s3_bucket_policy" "reports_website" {
  bucket = aws_s3_bucket.reports_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.reports_website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.reports_website]
}

# Upload do arquivo index.html
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.reports_website.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
}

# Configuração CORS para o bucket
resource "aws_s3_bucket_cors_configuration" "reports_website" {
  bucket = aws_s3_bucket.reports_website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Tabela DynamoDB para armazenar dados dos pets
resource "aws_dynamodb_table" "cadastropet" {
  name           = "cadastropet"
  billing_mode   = "PAY_PER_REQUEST"  # Modo on-demand para economizar custos
  hash_key       = "pet_id"
  
  # Chave primária
  attribute {
    name = "pet_id"
    type = "S"  # String
  }
  
  # Índices secundários para consultas eficientes
  attribute {
    name = "owner_name"
    type = "S"  # String
  }
  
  attribute {
    name = "pet_name"
    type = "S"  # String
  }
  
  attribute {
    name = "created_at"
    type = "S"  # String (ISO timestamp)
  }
  
  # Índice Global Secundário para buscar por dono
  global_secondary_index {
    name            = "owner-index"
    hash_key        = "owner_name"
    range_key       = "created_at"
    projection_type = "ALL"
  }
  
  # Índice Global Secundário para buscar por nome do pet
  global_secondary_index {
    name            = "pet-name-index"
    hash_key        = "pet_name"
    range_key       = "created_at"
    projection_type = "ALL"
  }
  
  # Tags para organização e custos
  tags = {
    Name        = "cadastropet"
    Environment = "production"
    Project     = "reports-app"
    Purpose     = "Pet registration data storage"
  }
  
  # Configurações de backup e ponto de recuperação
  point_in_time_recovery {
    enabled = true
  }
  
  # Configurações de criptografia
  server_side_encryption {
    enabled = true
  }
  
  # Configurações de TTL (Time To Live) - opcional, para limpeza automática
  ttl {
    attribute_name = "ttl"
    enabled        = false  # Desabilitado por padrão, pode ser habilitado se necessário
  }
}

# Outputs
output "website_url" {
  description = "URL do website hospedado no S3"
  value       = aws_s3_bucket_website_configuration.reports_website.website_endpoint
}

output "website_domain" {
  description = "Domínio do website"
  value       = aws_s3_bucket_website_configuration.reports_website.website_domain
}

output "bucket_name" {
  description = "Nome do bucket S3"
  value       = aws_s3_bucket.reports_website.bucket
}

output "bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.reports_website.arn
}

# Distribuição CloudFront para servir o website via HTTPS
resource "aws_cloudfront_distribution" "reports_website" {
  enabled             = true
  comment             = "reports-app website via CloudFront HTTPS"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.reports_website.website_endpoint
    origin_id   = "s3-website-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"      # CloudFront -> S3 website via HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https"   # Força HTTPS para o cliente
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"  # regiões mais comuns (barateia)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # HTTPS com domínio padrão do CloudFront
  }
}

output "cloudfront_domain" {
  description = "Domínio HTTPS do website (CloudFront)"
  value       = aws_cloudfront_distribution.reports_website.domain_name
}

# Outputs para DynamoDB
output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.cadastropet.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.cadastropet.arn
}

output "dynamodb_table_id" {
  description = "ID da tabela DynamoDB"
  value       = aws_dynamodb_table.cadastropet.id
}

output "dynamodb_table_stream_arn" {
  description = "ARN do stream da tabela DynamoDB"
  value       = aws_dynamodb_table.cadastropet.stream_arn
}
