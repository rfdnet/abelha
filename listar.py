import json
import boto3
from decimal import Decimal
from datetime import datetime

# Inicializar cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cadastropet')

def lambda_handler(event, context):
    """
    Função Lambda para listar pets da tabela DynamoDB
    
    Retorna todos os pets cadastrados ordenados por data de criação
    """
    
    try:
        # Configurar CORS headers
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        }
        
        # Verificar se é uma requisição OPTIONS (preflight)
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'CORS preflight successful'})
            }
        
        # Buscar todos os pets na tabela
        response = table.scan()
        pets = response.get('Items', [])
        
        # Ordenar por data de criação (mais recentes primeiro)
        pets.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        # Converter Decimal para int/float para serialização JSON
        def convert_decimals(obj):
            if isinstance(obj, Decimal):
                return int(obj) if obj % 1 == 0 else float(obj)
            elif isinstance(obj, list):
                return [convert_decimals(item) for item in obj]
            elif isinstance(obj, dict):
                return {key: convert_decimals(value) for key, value in obj.items()}
            return obj
        
        pets = convert_decimals(pets)
        
        # Log para CloudWatch
        print(f"Listando {len(pets)} pets cadastrados")
        
        # Resposta de sucesso
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': f'{len(pets)} pets encontrados',
                'success': True,
                'pets': pets,
                'total': len(pets)
            })
        }
        
    except Exception as e:
        # Log do erro
        print(f"Erro ao listar pets: {str(e)}")
        
        # Resposta de erro
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Erro interno do servidor',
                'success': False,
                'details': str(e)
            })
        }
