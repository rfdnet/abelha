# Deploy de Website Estático no AWS S3

Este projeto contém uma página HTML estática para cadastro de PETs e o script Terraform para fazer o deploy no AWS S3.

## 📁 Arquivos do Projeto

- `index.html` - Página HTML estática com formulário de cadastro de PETs
- `main.tf` - Script Terraform para deploy no AWS S3 e DynamoDB
- `cadastro.tf` - Script Terraform para AWS Lambda e API Gateway
- `cadastro.py` - Função Lambda em Python para cadastro de pets
- `update-api-url.sh` - Script para atualizar URL da API no HTML
- `README.md` - Este arquivo de documentação

## 🚀 Como fazer o Deploy

### Pré-requisitos

1. **AWS CLI configurado** com suas credenciais
2. **Terraform instalado** (versão 1.0+)
3. **Permissões adequadas** no AWS para criar recursos S3

### Passos para Deploy

1. **Clone ou baixe os arquivos** para seu ambiente local

2. **Navegue até o diretório** do projeto:
   ```bash
   cd reports-app
   ```

3. **Inicialize o Terraform**:
   ```bash
   terraform init
   ```

4. **Planeje a infraestrutura** (opcional, mas recomendado):
   ```bash
   terraform plan
   ```

5. **Execute o deploy**:
   ```bash
   terraform apply
   ```
   
   Digite `yes` quando solicitado para confirmar a criação dos recursos.

6. **Após o deploy**, atualize a URL da API no HTML:
   ```bash
   ./update-api-url.sh
   ```
   
   Este script irá:
   - Obter a URL da API Gateway do Terraform
   - Atualizar o arquivo `index.html` com a URL real
   - Fazer upload do arquivo atualizado para o S3

7. **Após o deploy**, o Terraform exibirá as informações dos recursos:
   ```
   website_url = "report1234-rdias.s3-website-us-east-1.amazonaws.com"
   dynamodb_table_name = "cadastropet"
   api_gateway_url = "https://abc123.execute-api.us-east-1.amazonaws.com/prod/cadastrar"
   ```

### 🌐 Acessando o Website

Após o deploy bem-sucedido, você poderá acessar o website através da URL fornecida no output do Terraform.

## 📋 Recursos Criados

O script Terraform criará os seguintes recursos na AWS:

### **S3 (Armazenamento Estático)**
- **S3 Bucket**: `report1234-rdias`
- **Website Hosting**: Configurado para hospedar o `index.html`
- **Política de Acesso Público**: Permite leitura pública dos arquivos
- **Configuração CORS**: Para compatibilidade com navegadores
- **Upload Automático**: Do arquivo `index.html`

### **DynamoDB (Banco de Dados NoSQL)**
- **Tabela**: `cadastropet`
- **Chave Primária**: `pet_id` (String)
- **Modo de Cobrança**: Pay-per-request (on-demand)
- **Índices Globais Secundários**:
  - `owner-index`: Busca por nome do dono
  - `pet-name-index`: Busca por nome do pet
- **Recursos de Segurança**:
  - Criptografia server-side habilitada
  - Point-in-time recovery habilitado
  - Tags para organização e controle de custos

### **AWS Lambda (Backend)**
- **Função**: `cadastro-pet`
- **Runtime**: Python 3.9
- **Timeout**: 30 segundos
- **Memória**: 128 MB
- **Funcionalidade**: Cadastra pets no DynamoDB
- **Permissões**: Acesso completo à tabela `cadastropet`

### **API Gateway (API REST)**
- **API**: `cadastro-pet-api`
- **Endpoint**: `/cadastrar`
- **Método**: POST
- **CORS**: Habilitado para todos os origins
- **Integração**: AWS Lambda Proxy

## 🔧 Configurações

### Região AWS
Por padrão, o bucket será criado na região `us-east-1`. Para alterar:

1. Edite o arquivo `main.tf`
2. Modifique a linha: `region = "us-east-1"`
3. Execute `terraform plan` e `terraform apply`

### Bucket Name
O bucket é criado com o nome `report1234-rdias` conforme solicitado.

## 🗑️ Removendo os Recursos

Para remover todos os recursos criados:

```bash
terraform destroy
```

Digite `yes` quando solicitado para confirmar a remoção.

## 📝 Funcionalidades da Página

A página HTML inclui:

- ✅ Formulário de cadastro de PETs
- ✅ Campos: Nome do Pet, Idade, Nome do Dono
- ✅ Validação JavaScript
- ✅ Design responsivo e moderno
- ✅ Feedback visual para o usuário

## 🛠️ Customizações

### Adicionando mais páginas
Para adicionar mais arquivos HTML:

1. Adicione os arquivos no diretório
2. Crie novos recursos `aws_s3_object` no `main.tf`
3. Execute `terraform apply`

### Alterando o bucket name
Para usar um nome diferente:

1. Edite a linha `bucket = "report1234-rdias"` no `main.tf`
2. Execute `terraform plan` e `terraform apply`

### Configurações do DynamoDB
Para modificar a tabela `cadastropet`:

1. **Modo de cobrança**: Altere `billing_mode` de `PAY_PER_REQUEST` para `PROVISIONED`
2. **Índices**: Adicione ou remova `global_secondary_index` conforme necessário
3. **TTL**: Habilite `ttl.enabled = true` para limpeza automática de registros antigos
4. Execute `terraform plan` e `terraform apply`

### Estrutura da Tabela DynamoDB
```json
{
  "pet_id": "string (chave primária)",
  "pet_name": "string",
  "owner_name": "string", 
  "pet_age": "number",
  "created_at": "string (ISO timestamp)",
  "ttl": "number (opcional)"
}
```

## ⚠️ Considerações de Segurança

### **S3 Bucket**
- O bucket está configurado para acesso público de leitura
- Apenas arquivos estáticos são servidos
- Não há execução de código server-side
- Ideal para websites estáticos simples

### **DynamoDB**
- Tabela com criptografia server-side habilitada
- Point-in-time recovery configurado para backup
- Modo pay-per-request para controle de custos
- Índices otimizados para consultas eficientes
- Tags para organização e auditoria de recursos

## 📞 Suporte

Em caso de problemas:

1. Verifique as credenciais AWS
2. Confirme as permissões do usuário
3. Execute `terraform plan` para validar a configuração
4. Verifique os logs do Terraform para erros específicos
# abelha
