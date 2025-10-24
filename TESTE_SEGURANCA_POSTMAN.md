# 🔒 Guia de Teste de Segurança - API Keys no Postman

## 📋 Informações da API

- **API Key**: `uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ`
- **URL Base**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod`
- **CloudFront**: `https://dxylcq1l3pspj.cloudfront.net`

## 🎯 Endpoints Disponíveis

1. **Cadastrar Pet** - `POST /cadastrar`
2. **Listar Pets** - `GET /listar`
3. **Deletar Pet** - `DELETE /deletar/{pet_id}`

---

## 🧪 Testes de Segurança no Postman

### ✅ Teste 1: Requisição SEM API Key (Deve FALHAR)

Este teste verifica se a API está realmente protegida.

#### Cadastrar Pet - SEM API Key

1. **Método**: `POST`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/cadastrar`
3. **Headers**:
   ```
   Content-Type: application/json
   ```
4. **Body** (raw JSON):
   ```json
   {
     "pet_name": "Rex",
     "pet_age": 5,
     "owner_name": "João Silva"
   }
   ```

**Resultado Esperado**: 
- Status: `403 Forbidden`
- Mensagem: `{"message":"Forbidden"}`

---

### ✅ Teste 2: Requisição COM API Key (Deve FUNCIONAR)

Este teste verifica se a API Key está funcionando corretamente.

#### Cadastrar Pet - COM API Key

1. **Método**: `POST`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/cadastrar`
3. **Headers**:
   ```
   Content-Type: application/json
   x-api-key: uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ
   ```
4. **Body** (raw JSON):
   ```json
   {
     "pet_name": "Rex",
     "pet_age": 5,
     "owner_name": "João Silva"
   }
   ```

**Resultado Esperado**: 
- Status: `200 OK`
- Resposta:
  ```json
  {
    "success": true,
    "message": "Pet cadastrado com sucesso!",
    "pet_id": "uuid-gerado",
    "data": {
      "pet_id": "uuid-gerado",
      "pet_name": "Rex",
      "pet_age": 5,
      "owner_name": "João Silva",
      "created_at": "2025-10-24T16:45:00.000Z"
    }
  }
  ```

---

### ✅ Teste 3: Listar Pets - SEM API Key

1. **Método**: `GET`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/listar`
3. **Headers**: (nenhum)

**Resultado Esperado**: 
- Status: `403 Forbidden`
- Mensagem: `{"message":"Forbidden"}`

---

### ✅ Teste 4: Listar Pets - COM API Key

1. **Método**: `GET`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/listar`
3. **Headers**:
   ```
   x-api-key: uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ
   ```

**Resultado Esperado**: 
- Status: `200 OK`
- Resposta:
  ```json
  {
    "success": true,
    "pets": [
      {
        "pet_id": "uuid",
        "pet_name": "Rex",
        "pet_age": 5,
        "owner_name": "João Silva",
        "created_at": "2025-10-24T16:45:00.000Z"
      }
    ]
  }
  ```

---

### ✅ Teste 5: Deletar Pet - SEM API Key

1. **Método**: `DELETE`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/deletar/{pet_id}`
   - Substitua `{pet_id}` pelo ID de um pet existente
3. **Headers**: (nenhum)

**Resultado Esperado**: 
- Status: `403 Forbidden`
- Mensagem: `{"message":"Forbidden"}`

---

### ✅ Teste 6: Deletar Pet - COM API Key

1. **Método**: `DELETE`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/deletar/{pet_id}`
   - Substitua `{pet_id}` pelo ID de um pet existente
3. **Headers**:
   ```
   x-api-key: uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ
   ```

**Resultado Esperado**: 
- Status: `200 OK`
- Resposta:
  ```json
  {
    "success": true,
    "message": "Pet deletado com sucesso!"
  }
  ```

---

### ✅ Teste 7: API Key Inválida

Este teste verifica se a API rejeita chaves inválidas.

1. **Método**: `GET`
2. **URL**: `https://jncx39loi4.execute-api.us-west-2.amazonaws.com/prod/listar`
3. **Headers**:
   ```
   x-api-key: chave-invalida-123456
   ```

**Resultado Esperado**: 
- Status: `403 Forbidden`
- Mensagem: `{"message":"Forbidden"}`

---

## 📊 Configurações de Segurança Implementadas

### 🔐 API Key
- **Nome**: `cadastro-pet-api-key`
- **Status**: Habilitada
- **Valor**: `uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ`

### 🚦 Rate Limiting (Usage Plan)
- **Quota Diária**: 10.000 requisições/dia
- **Rate Limit**: 50 requisições/segundo
- **Burst Limit**: 100 requisições simultâneas

### 🛡️ Proteções Ativas
1. ✅ Todas as APIs exigem API Key
2. ✅ Rate limiting configurado
3. ✅ CORS restrito ao domínio CloudFront
4. ✅ HTTPS obrigatório
5. ✅ Logs habilitados no CloudWatch

---

## 🎬 Como Importar no Postman

### Opção 1: Criar Collection Manualmente

1. Abra o Postman
2. Clique em "New" → "Collection"
3. Nomeie como "Cadastro de Pets - API Segura"
4. Adicione cada endpoint conforme os testes acima

### Opção 2: Configurar API Key Global

1. Na Collection, vá em "Variables"
2. Adicione uma variável:
   - **Variable**: `api_key`
   - **Initial Value**: `uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ`
   - **Current Value**: `uL879J2IMq3o67z9Xl3Ay8C4DxRbwYmE3CoDQZHZ`
3. Nos headers, use: `x-api-key: {{api_key}}`

---

## 🔍 Monitoramento

### Ver Logs no CloudWatch

```bash
# Logs de cadastro
aws logs tail /aws/lambda/cadastro-pet --follow

# Logs de listagem
aws logs tail /aws/lambda/listar-pets --follow

# Logs de exclusão
aws logs tail /aws/lambda/deletar-pet --follow
```

### Ver Métricas de Uso

```bash
# Ver uso da API Key
aws apigateway get-usage \
  --usage-plan-id 8joqa1 \
  --key-id 86bqug3jvd \
  --start-date 2025-10-24 \
  --end-date 2025-10-25
```

---

## 🚨 Troubleshooting

### Erro: "Forbidden" mesmo com API Key

1. Verifique se o header é `x-api-key` (minúsculo)
2. Confirme que não há espaços extras na chave
3. Verifique se a API Key está habilitada no AWS Console

### Erro: "Too Many Requests"

- Você atingiu o rate limit
- Aguarde alguns segundos antes de tentar novamente
- Verifique o Usage Plan no AWS Console

### Como Obter a API Key Novamente

```bash
terraform output -raw api_key
```

---

## ✅ Checklist de Segurança

- [x] API Key implementada
- [x] Rate limiting configurado
- [x] CORS restrito
- [x] HTTPS obrigatório
- [x] Logs habilitados
- [x] Métodos OPTIONS não exigem API Key (para CORS)
- [x] Todos os métodos de negócio exigem API Key

---

## 📝 Notas Importantes

1. **Nunca compartilhe a API Key publicamente**
2. **Rotacione a API Key periodicamente**
3. **Monitore o uso através do CloudWatch**
4. **Configure alertas para uso anormal**
5. **A API Key está embutida no frontend para fins de demonstração**
   - Em produção, considere usar Cognito ou OAuth

---

## 🎉 Conclusão

Sua API agora está protegida com:
- ✅ Autenticação via API Key
- ✅ Rate limiting
- ✅ Quota diária
- ✅ Logs e monitoramento

Teste todos os cenários no Postman para validar a segurança!
