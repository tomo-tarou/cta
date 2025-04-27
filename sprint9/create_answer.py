import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # 1. 必須パラメータのチェック
    if 'id' not in event:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Parameter error: missing required parameter(s)',
                'missing_params': ['id']
            })
        }
    
    # 2. 入力パラメータの取得
    inquiry_id = event["id"]
    
    try:
        # 3. DynamoDBリソースの初期化
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('InquiryTable')
        
        # 4. DynamoDBから問い合わせ内容を取得
        response = table.get_item(Key={'id': inquiry_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': f'Inquiry with id {inquiry_id} not found'
                })
            }
        
        inquiry_item = response['Item']
        review_text = inquiry_item.get('reviewText', '')
        
        # 5. Bedrockを使って回答を生成（RAGデータを活用）
        bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')
        
        rag_response = bedrock_agent_runtime.retrieve_and_generate(
            input={
                "text": review_text
            },
            retrieveAndGenerateConfiguration={
                "type": "KNOWLEDGE_BASE",
                "knowledgeBaseConfiguration": {
                    "knowledgeBaseId": "xxxxxx",
                    "modelArn": "xxxxxx"
                }
            }
        )
        
        generated_answer = rag_response["output"]["text"]
        
        # 6. タイムスタンプの取得
        timestamp = datetime.now().isoformat()
        
        # 7. 問い合わせテーブルを更新（回答を登録）
        table.update_item(
            Key={'id': inquiry_id},
            UpdateExpression="SET answer = :answer, updatedAt = :updatedAt",
            ExpressionAttributeValues={
                ':answer': generated_answer,
                ':updatedAt': timestamp
            }
        )
        
        # 8. 正常終了
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Answer generated and saved successfully!',
                'id': inquiry_id,
                'answer': generated_answer
            })
        }
        
    except Exception as e:
        # 9. エラーが発生した場合、ステータスコード500を返す
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error generating answer: {str(e)}')
        }

