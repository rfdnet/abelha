# Site estático no S3 (Terraform)

Projeto simples: uma página HTML de cadastro de PETs hospedada em um bucket S3. Infra como código com Terraform.

## Arquivos
- `index.html` — página estática
- `main.tf` — S3 e DynamoDB
- `cadastro.tf` — Lambda e API Gateway
- `cadastro.py` — função Lambda
- `update-api-url.sh` — atualiza a URL da API no HTML

## Pré-requisitos
- AWS CLI configurado
- Terraform 1.0+
- Permissões para criar S3, DynamoDB, Lambda e API Gateway

## Deploy rápido
```bash
terraform init
terraform apply   # confirme com "yes"
./update-api-url.sh  # atualiza a URL da API no index.html e envia ao S3
```

Após o apply, o Terraform mostra as saídas (ex.: `website_url` e `api_gateway_url`). Use a URL para acessar o site.

## Acessar
- Abra a `website_url` exibida no output do Terraform.

## Remover
```bash
terraform destroy
```

## Dicas
- Região padrão: `us-east-1` (ajuste em `main.tf` se precisar)
- Para trocar o nome do bucket, altere `bucket = "<nome>"` em `main.tf` e rode `terraform apply`

## Suporte
- Revise credenciais e permissões da AWS
- Rode `terraform plan` para validar
- Verifique mensagens de erro do Terraform
