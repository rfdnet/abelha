import json
import boto3
from datetime import datetime

# Inicializar cliente DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cadastropet')

def lambda_handler(event, context):
    """
    Função Lambda para deletar pets da tabela DynamoDB
    
    Recebe pet_id via DELETE request e remove o pet da tabela
    """
    
    try:
        # Configurar CORS headers
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
        }
        
        # Verificar se é uma requisição OPTIONS (preflight)
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'CORS preflight successful'})
            }
        
        # Extrair pet_id do path parameters ou query string
        pet_id = None
        
        # Tentar obter do path parameters primeiro
        if event.get('pathParameters') and event.get('pathParameters').get('pet_id'):
            pet_id = event['pathParameters']['pet_id']
        # Se não estiver no path, tentar query string
        elif event.get('queryStringParameters') and event.get('queryStringParameters').get('pet_id'):
            pet_id = event['queryStringParameters']['pet_id']
        # Se não estiver em nenhum lugar, tentar body
        elif event.get('body'):
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
            pet_id = body.get('pet_id')
        
        # Validar se pet_id foi fornecido
        if not pet_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'pet_id é obrigatório',
                    'success': False
                })
            }
        
        # Verificar se o pet existe antes de deletar
        try:
            response = table.get_item(Key={'pet_id': pet_id})
            if 'Item' not in response:
                return {
                    'statusCode': 404,
                    'headers': headers,
                    'body': json.dumps({
                        'error': 'Pet não encontrado',
                        'success': False
                    })
                }
            
            pet_data = response['Item']
            
        except Exception as e:
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Erro ao verificar pet',
                    'success': False,
                    'details': str(e)
                })
            }
        
        # Deletar o pet do DynamoDB
        try:
            delete_response = table.delete_item(
                Key={'pet_id': pet_id},
                ReturnValues='ALL_OLD'
            )
            
            deleted_item = delete_response.get('Attributes', {})
            
            # Log para CloudWatch
            print(f"Pet deletado com sucesso: {pet_id}")
            print(f"Dados deletados: {deleted_item}")
            
            # Resposta de sucesso
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Pet deletado com sucesso!',
                    'success': True,
                    'deleted_pet': {
                        'pet_id': pet_id,
                        'pet_name': deleted_item.get('pet_name', 'N/A'),
                        'owner_name': deleted_item.get('owner_name', 'N/A')
                    }
                })
            }
            
        except Exception as e:
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Erro ao deletar pet',
                    'success': False,
                    'details': str(e)
                })
            }
        
    except Exception as e:
        # Log do erro
        print(f"Erro ao processar exclusão: {str(e)}")
        
        # Resposta de erro
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'DELETE,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Erro interno do servidor',
                'success': False,
                'details': str(e)
            })
        }
