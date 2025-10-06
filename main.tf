# Configuração do Provider AWS
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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control for CloudFront -> S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "reports-app-oac"
  description                       = "OAC for CloudFront to access S3 privately"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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
    allowed_origins = ["https://${aws_cloudfront_distribution.reports_website.domain_name}"]
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
    domain_name              = aws_s3_bucket.reports_website.bucket_regional_domain_name
    origin_id                = "s3-rest-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-rest-origin"
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

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
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

# Bucket policy to allow access only from CloudFront via OAC
resource "aws_s3_bucket_policy" "reports_website_oac" {
  bucket = aws_s3_bucket.reports_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowCloudFrontServicePrincipalReadOnly",
        Effect: "Allow",
        Principal: { Service: "cloudfront.amazonaws.com" },
        Action: ["s3:GetObject"],
        Resource: ["${aws_s3_bucket.reports_website.arn}/*"],
        Condition: {
          StringEquals: {
            "AWS:SourceArn": aws_cloudfront_distribution.reports_website.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.reports_website]
}

# CloudFront Function to add basic security headers
resource "aws_cloudfront_function" "security_headers" {
  name    = "reports-app-security-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Add baseline security headers"
  publish = true

  code = <<-EOT
function handler(event) {
  var response = event.response;
  var headers = response.headers;
  headers['strict-transport-security'] = {value: 'max-age=31536000; includeSubDomains; preload'};
  headers['x-content-type-options'] = {value: 'nosniff'};
  headers['referrer-policy'] = {value: 'strict-origin-when-cross-origin'};
  headers['permissions-policy'] = {value: 'microphone=(self)'};
  // Basic CSP; consider hashing/nonce if moving inline JS to external file
  headers['content-security-policy'] = {value: "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https:"};
  return response;
}
EOT
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
