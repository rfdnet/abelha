import json
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

# Inicializar cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cadastropet')

def lambda_handler(event, context):
    """
    Função Lambda para cadastrar pets na tabela DynamoDB
    
    Recebe dados via POST request e salva na tabela cadastropet
    """
    
    try:
        # Configurar CORS headers
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        }
        
        # Verificar se é uma requisição OPTIONS (preflight)
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'CORS preflight successful'})
            }
        
        # Extrair dados do body da requisição
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        # Validar dados obrigatórios
        pet_name = body.get('pet_name', '').strip()
        pet_age = body.get('pet_age')
        owner_name = body.get('owner_name', '').strip()
        
        # Validações
        if not pet_name:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Nome do pet é obrigatório',
                    'success': False
                })
            }
        
        if not owner_name:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Nome do dono é obrigatório',
                    'success': False
                })
            }
        
        if pet_age is None or pet_age == '':
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Idade do pet é obrigatória',
                    'success': False
                })
            }
        
        # Converter idade para número
        try:
            pet_age = int(pet_age)
            if pet_age < 0 or pet_age > 30:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({
                        'error': 'Idade deve estar entre 0 e 30 anos',
                        'success': False
                    })
                }
        except (ValueError, TypeError):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Idade deve ser um número válido',
                    'success': False
                })
            }
        
        # Gerar ID único para o pet
        pet_id = str(uuid.uuid4())
        
        # Timestamp atual
        created_at = datetime.utcnow().isoformat() + 'Z'
        
        # Item para salvar no DynamoDB
        item = {
            'pet_id': pet_id,
            'pet_name': pet_name,
            'owner_name': owner_name,
            'pet_age': pet_age,  # DynamoDB aceita números nativos
            'created_at': created_at
        }
        
        # Salvar no DynamoDB
        response = table.put_item(Item=item)
        
        # Log para CloudWatch
        print(f"Pet cadastrado com sucesso: {pet_id}")
        print(f"Dados: {item}")
        
        # Resposta de sucesso
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Pet cadastrado com sucesso!',
                'success': True,
                'pet_id': pet_id,
                'data': {
                    'pet_name': pet_name,
                    'pet_age': pet_age,
                    'owner_name': owner_name,
                    'created_at': created_at
                }
            })
        }
        
    except Exception as e:
        # Log do erro
        print(f"Erro ao cadastrar pet: {str(e)}")
        
        # Resposta de erro
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Erro interno do servidor',
                'success': False,
                'details': str(e)
            })
        }
