#!/bin/bash

# Script para atualizar a URL da API Gateway no arquivo HTML
# Execute este script após o terraform apply

echo "🔧 Atualizando URL da API Gateway no index.html..."

# Obter as URLs da API Gateway do output do Terraform
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
LISTAR_API_URL=$(terraform output -raw api_gateway_listar_url 2>/dev/null)
DELETE_API_URL=$(terraform output -raw api_gateway_deletar_url 2>/dev/null)

if [ -z "$API_URL" ] || [ -z "$LISTAR_API_URL" ] || [ -z "$DELETE_API_URL" ]; then
    echo "❌ Erro: Não foi possível obter as URLs da API Gateway do Terraform"
    echo "Certifique-se de que o terraform apply foi executado com sucesso"
    exit 1
fi

echo "📡 URL da API de cadastro encontrada: $API_URL"
echo "📡 URL da API de listar encontrada: $LISTAR_API_URL"
echo "📡 URL da API de deletar encontrada: $DELETE_API_URL"

# Verificar se o arquivo index.html existe
if [ ! -f "index.html" ]; then
    echo "❌ Erro: Arquivo index.html não encontrado"
    exit 1
fi

# Substituir os placeholders pelas URLs reais
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|REPLACE_WITH_API_URL|$API_URL|g" index.html
    sed -i '' "s|REPLACE_WITH_LISTAR_API_URL|$LISTAR_API_URL|g" index.html
    sed -i '' "s|REPLACE_WITH_DELETE_API_URL|$DELETE_API_URL|g" index.html
else
    # Linux
    sed -i "s|REPLACE_WITH_API_URL|$API_URL|g" index.html
    sed -i "s|REPLACE_WITH_LISTAR_API_URL|$LISTAR_API_URL|g" index.html
    sed -i "s|REPLACE_WITH_DELETE_API_URL|$DELETE_API_URL|g" index.html
fi

echo "✅ URLs da API atualizadas com sucesso no index.html"

# Fazer upload do arquivo atualizado para o S3
echo "📤 Fazendo upload do index.html atualizado para o S3..."

BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Erro: Não foi possível obter o nome do bucket S3"
    exit 1
fi

aws s3 cp index.html s3://$BUCKET_NAME/index.html --content-type "text/html"

if [ $? -eq 0 ]; then
    echo "✅ Arquivo index.html atualizado no S3 com sucesso!"
    echo "🌐 Seu website está atualizado e funcionando com a API Lambda!"
else
    echo "❌ Erro ao fazer upload para o S3"
    echo "Certifique-se de que o AWS CLI está configurado corretamente"
    exit 1
fi

echo ""
echo "🎉 Processo concluído!"
echo "📋 Resumo:"
echo "   - URL da API de cadastro: $API_URL"
echo "   - URL da API de listar: $LISTAR_API_URL"
echo "   - URL da API de deletar: $DELETE_API_URL"
echo "   - Bucket S3: $BUCKET_NAME"
echo "   - Website: $(terraform output -raw website_url)"
