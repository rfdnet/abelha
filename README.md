# Cadastro de PETs na AWS

Sistema de cadastro de PETs com reconhecimento de voz usando AWS.

## Como usar

1. **Deploy**
```bash
terraform init
terraform apply -auto-approve
./update-api-url.sh
```

2. **Acessar**
- Abra o link CloudFront gerado
- Clique no botão 🎤 para usar voz
- Autorize o microfone

3. **Remover**
```bash
terraform destroy
```

## Tecnologias

- **Frontend**: S3 + CloudFront (HTTPS)
- **Backend**: Lambda + API Gateway
- **Banco**: DynamoDB
- **Voz**: Web Speech API (Chrome/Edge)

## Arquivos

- `index.html` — página web
- `main.tf` — infraestrutura AWS
- `cadastro.tf` — API Lambda
- `update-api-url.sh` — deploy

## Problemas comuns

- **Microfone não funciona**: use HTTPS (CloudFront)
- **Permissão negada**: libere microfone no navegador
- **Idade não preenche**: fale números de 0 a 30