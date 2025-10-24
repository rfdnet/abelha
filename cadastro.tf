# Arquivo de infraestrutura para Lambda de cadastro de pets

# Data source para obter a região atual
data "aws_region" "current" {}

# Data source para obter informações da conta
data "aws_caller_identity" "current" {}

# Criar arquivo ZIP para a função Lambda de cadastro
data "archive_file" "cadastro_lambda_zip" {
  type        = "zip"
  source_file = "cadastro.py"
  output_path = "cadastro_lambda.zip"
}

# Criar arquivo ZIP para a função Lambda de listar
data "archive_file" "listar_lambda_zip" {
  type        = "zip"
  source_file = "listar.py"
  output_path = "listar_lambda.zip"
}

# Criar arquivo ZIP para a função Lambda de deletar
data "archive_file" "deletar_lambda_zip" {
  type        = "zip"
  source_file = "deletar.py"
  output_path = "deletar_lambda.zip"
}

# Role IAM para a função Lambda
resource "aws_iam_role" "lambda_cadastro_role" {
  name = "lambda-cadastro-pet-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "lambda-cadastro-pet-role"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Política IAM para permitir logs do CloudWatch
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "lambda-cadastro-logs-policy"
  role = aws_iam_role.lambda_cadastro_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Política IAM para permitir acesso ao DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda-cadastro-dynamodb-policy"
  role = aws_iam_role.lambda_cadastro_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.cadastropet.arn,
          "${aws_dynamodb_table.cadastropet.arn}/index/*"
        ]
      }
    ]
  })
}

# Função Lambda para cadastrar pets
resource "aws_lambda_function" "cadastro_pet" {
  filename         = data.archive_file.cadastro_lambda_zip.output_path
  function_name    = "cadastro-pet"
  role            = aws_iam_role.lambda_cadastro_role.arn
  handler         = "cadastro.lambda_handler"
  runtime         = "python3.11"
  timeout         = 5
  memory_size     = 128

  source_code_hash = data.archive_file.cadastro_lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.cadastropet.name
    }
  }

  tags = {
    Name        = "cadastro-pet-lambda"
    Environment = "production"
    Project     = "reports-app"
    Purpose     = "Pet registration function"
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs_policy,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# Função Lambda para listar pets
resource "aws_lambda_function" "listar_pets" {
  filename         = data.archive_file.listar_lambda_zip.output_path
  function_name    = "listar-pets"
  role            = aws_iam_role.lambda_cadastro_role.arn
  handler         = "listar.lambda_handler"
  runtime         = "python3.11"
  timeout         = 5
  memory_size     = 128

  source_code_hash = data.archive_file.listar_lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.cadastropet.name
    }
  }

  tags = {
    Name        = "listar-pets-lambda"
    Environment = "production"
    Project     = "reports-app"
    Purpose     = "Pet listing function"
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs_policy,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_cloudwatch_log_group.lambda_listar_logs
  ]
}

# Função Lambda para deletar pets
resource "aws_lambda_function" "deletar_pet" {
  filename         = data.archive_file.deletar_lambda_zip.output_path
  function_name    = "deletar-pet"
  role            = aws_iam_role.lambda_cadastro_role.arn
  handler         = "deletar.lambda_handler"
  runtime         = "python3.11"
  timeout         = 5
  memory_size     = 128

  source_code_hash = data.archive_file.deletar_lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.cadastropet.name
    }
  }

  tags = {
    Name        = "deletar-pet-lambda"
    Environment = "production"
    Project     = "reports-app"
    Purpose     = "Pet deletion function"
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs_policy,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_cloudwatch_log_group.lambda_deletar_logs
  ]
}

# Log Group para a função Lambda de cadastro
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/cadastro-pet"
  retention_in_days = 7

  tags = {
    Name        = "cadastro-pet-logs"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Log Group para a função Lambda de listar
resource "aws_cloudwatch_log_group" "lambda_listar_logs" {
  name              = "/aws/lambda/listar-pets"
  retention_in_days = 7

  tags = {
    Name        = "listar-pets-logs"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Log Group para a função Lambda de deletar
resource "aws_cloudwatch_log_group" "lambda_deletar_logs" {
  name              = "/aws/lambda/deletar-pet"
  retention_in_days = 7

  tags = {
    Name        = "deletar-pet-logs"
    Environment = "production"
    Project     = "reports-app"
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "cadastro_api" {
  name        = "cadastro-pet-api"
  description = "API para cadastro de pets"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  minimum_compression_size = 1024

  tags = {
    Name        = "cadastro-pet-api"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Recurso para o endpoint de cadastro
resource "aws_api_gateway_resource" "cadastro_resource" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  parent_id   = aws_api_gateway_rest_api.cadastro_api.root_resource_id
  path_part   = "cadastrar"
}

# Recurso para o endpoint de listar pets
resource "aws_api_gateway_resource" "listar_resource" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  parent_id   = aws_api_gateway_rest_api.cadastro_api.root_resource_id
  path_part   = "listar"
}

# Recurso para o endpoint de deletar pets
resource "aws_api_gateway_resource" "deletar_resource" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  parent_id   = aws_api_gateway_rest_api.cadastro_api.root_resource_id
  path_part   = "deletar"
}

# Recurso para o endpoint de deletar pet específico (com ID)
resource "aws_api_gateway_resource" "deletar_pet_resource" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  parent_id   = aws_api_gateway_resource.deletar_resource.id
  path_part   = "{pet_id}"
}

# Método POST para cadastrar pets
resource "aws_api_gateway_method" "cadastro_post" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.cadastro_resource.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# Método OPTIONS para CORS (cadastro)
resource "aws_api_gateway_method" "cadastro_options" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.cadastro_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Método GET para listar pets
resource "aws_api_gateway_method" "listar_get" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.listar_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

# Método OPTIONS para CORS (listar)
resource "aws_api_gateway_method" "listar_options" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.listar_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Método DELETE para deletar pets
resource "aws_api_gateway_method" "deletar_delete" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.deletar_pet_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
  api_key_required = true
}

# Método OPTIONS para CORS (deletar)
resource "aws_api_gateway_method" "deletar_options" {
  rest_api_id   = aws_api_gateway_rest_api.cadastro_api.id
  resource_id   = aws_api_gateway_resource.deletar_pet_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração da Lambda com o método POST
resource "aws_api_gateway_integration" "cadastro_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.cadastro_resource.id
  http_method = aws_api_gateway_method.cadastro_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.cadastro_pet.invoke_arn
}

# Integração para CORS (OPTIONS - cadastro)
resource "aws_api_gateway_integration" "cadastro_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.cadastro_resource.id
  http_method = aws_api_gateway_method.cadastro_options.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Integração da Lambda com o método GET (listar)
resource "aws_api_gateway_integration" "listar_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.listar_resource.id
  http_method = aws_api_gateway_method.listar_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.listar_pets.invoke_arn
}

# Integração para CORS (OPTIONS - listar)
resource "aws_api_gateway_integration" "listar_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.listar_resource.id
  http_method = aws_api_gateway_method.listar_options.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Integração da Lambda com o método DELETE
resource "aws_api_gateway_integration" "deletar_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.deletar_pet_resource.id
  http_method = aws_api_gateway_method.deletar_delete.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.deletar_pet.invoke_arn
}

# Integração para CORS (OPTIONS - deletar)
resource "aws_api_gateway_integration" "deletar_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.deletar_pet_resource.id
  http_method = aws_api_gateway_method.deletar_options.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Resposta para método OPTIONS (CORS)
resource "aws_api_gateway_method_response" "cadastro_options_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.cadastro_resource.id
  http_method = aws_api_gateway_method.cadastro_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integração response para OPTIONS (cadastro)
resource "aws_api_gateway_integration_response" "cadastro_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.cadastro_resource.id
  http_method = aws_api_gateway_method.cadastro_options.http_method
  status_code = aws_api_gateway_method_response.cadastro_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.reports_website.domain_name}'"
  }

  depends_on = [aws_api_gateway_integration.cadastro_options_integration]
}

# Resposta para método OPTIONS (CORS - listar)
resource "aws_api_gateway_method_response" "listar_options_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.listar_resource.id
  http_method = aws_api_gateway_method.listar_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integração response para OPTIONS (listar)
resource "aws_api_gateway_integration_response" "listar_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.listar_resource.id
  http_method = aws_api_gateway_method.listar_options.http_method
  status_code = aws_api_gateway_method_response.listar_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.reports_website.domain_name}'"
  }

  depends_on = [aws_api_gateway_integration.listar_options_integration]
}

# Resposta para método OPTIONS (CORS - deletar)
resource "aws_api_gateway_method_response" "deletar_options_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.deletar_pet_resource.id
  http_method = aws_api_gateway_method.deletar_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integração response para OPTIONS (deletar)
resource "aws_api_gateway_integration_response" "deletar_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  resource_id = aws_api_gateway_resource.deletar_pet_resource.id
  http_method = aws_api_gateway_method.deletar_options.http_method
  status_code = aws_api_gateway_method_response.deletar_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.reports_website.domain_name}'"
  }

  depends_on = [aws_api_gateway_integration.deletar_options_integration]
}

# Permissão para API Gateway invocar a Lambda de cadastro
resource "aws_lambda_permission" "api_gateway_cadastro_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayCadastro"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cadastro_pet.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cadastro_api.execution_arn}/*/*"
}

# Permissão para API Gateway invocar a Lambda de listar
resource "aws_lambda_permission" "api_gateway_listar_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayListar"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.listar_pets.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cadastro_api.execution_arn}/*/*"
}

# Permissão para API Gateway invocar a Lambda de deletar
resource "aws_lambda_permission" "api_gateway_deletar_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayDeletar"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deletar_pet.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cadastro_api.execution_arn}/*/*"
}

# Deployment da API Gateway
resource "aws_api_gateway_deployment" "cadastro_deployment" {
  depends_on = [
    aws_api_gateway_integration.cadastro_integration,
    aws_api_gateway_integration.listar_integration,
    aws_api_gateway_integration.deletar_integration,
    aws_api_gateway_integration_response.cadastro_options_integration_response,
    aws_api_gateway_integration_response.listar_options_integration_response,
    aws_api_gateway_integration_response.deletar_options_integration_response,
    aws_api_gateway_method.cadastro_post,
    aws_api_gateway_method.listar_get,
    aws_api_gateway_method.deletar_delete
  ]

  rest_api_id = aws_api_gateway_rest_api.cadastro_api.id
  stage_name  = "prod"

  # Forçar redeploy quando os métodos mudarem
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.cadastro_post.id,
      aws_api_gateway_method.listar_get.id,
      aws_api_gateway_method.deletar_delete.id,
      aws_api_gateway_integration.cadastro_integration.id,
      aws_api_gateway_integration.listar_integration.id,
      aws_api_gateway_integration.deletar_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Key para segurança
resource "aws_api_gateway_api_key" "cadastro_api_key" {
  name        = "cadastro-pet-api-key"
  description = "API Key para acesso ao sistema de cadastro de pets"
  enabled     = true

  tags = {
    Name        = "cadastro-pet-api-key"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Usage Plan com rate limiting
resource "aws_api_gateway_usage_plan" "cadastro_usage_plan" {
  name        = "cadastro-pet-usage-plan"
  description = "Usage plan para API de cadastro de pets com rate limiting"

  api_stages {
    api_id = aws_api_gateway_rest_api.cadastro_api.id
    stage  = aws_api_gateway_deployment.cadastro_deployment.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }

  tags = {
    Name        = "cadastro-pet-usage-plan"
    Environment = "production"
    Project     = "reports-app"
  }
}

# Associar API Key ao Usage Plan
resource "aws_api_gateway_usage_plan_key" "cadastro_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.cadastro_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.cadastro_usage_plan.id
}

# Outputs
output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.cadastro_pet.function_name
}

output "lambda_function_arn" {
  description = "ARN da função Lambda"
  value       = aws_lambda_function.cadastro_pet.arn
}

output "api_gateway_url" {
  description = "URL da API Gateway"
  value       = "${aws_api_gateway_deployment.cadastro_deployment.invoke_url}/cadastrar"
}

output "api_gateway_listar_url" {
  description = "URL da API Gateway para listar pets"
  value       = "${aws_api_gateway_deployment.cadastro_deployment.invoke_url}/listar"
}

output "api_gateway_id" {
  description = "ID da API Gateway"
  value       = aws_api_gateway_rest_api.cadastro_api.id
}

output "listar_lambda_function_name" {
  description = "Nome da função Lambda de listar"
  value       = aws_lambda_function.listar_pets.function_name
}

output "listar_lambda_function_arn" {
  description = "ARN da função Lambda de listar"
  value       = aws_lambda_function.listar_pets.arn
}

output "api_gateway_deletar_url" {
  description = "URL da API Gateway para deletar pets"
  value       = "${aws_api_gateway_deployment.cadastro_deployment.invoke_url}/deletar"
}

output "deletar_lambda_function_name" {
  description = "Nome da função Lambda de deletar"
  value       = aws_lambda_function.deletar_pet.function_name
}

output "deletar_lambda_function_arn" {
  description = "ARN da função Lambda de deletar"
  value       = aws_lambda_function.deletar_pet.arn
}

output "api_key" {
  description = "API Key para acesso às APIs"
  value       = aws_api_gateway_api_key.cadastro_api_key.value
  sensitive   = true
}
