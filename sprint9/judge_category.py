import json
import boto3
from datetime import datetime
from enum import Enum

class Category(Enum):
    QUESTION = "質問"
    IMPROVEMENT = "改善要望"
    POSITIVE = "ポジティブな感想"
    NEGATIVE = "ネガティブな感想"
    OTHER = "その他"

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
    
    inquiry_id = event["id"]
    
    try:
        # 2. DynamoDBリソースの初期化
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('InquiryTable')
        
        # 3. 問い合わせ内容の取得
        response = table.get_item(Key={'id': inquiry_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'message': f'Inquiry with id {inquiry_id} not found'
                })
            }
        
        item = response['Item']
        review_text = item.get('reviewText', '')
        
        # 4. Bedrockによる分類
        bedrock = boto3.client('bedrock-runtime')
        
        prompt = f"""
        以下のユーザーの問い合わせを分類してください。分類結果のみを返答してください。
        選択肢: {[c.value for c in Category]}

        問い合わせ内容:
        {review_text}
        """
        
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 100,
            "system": "あなたは優秀なカスタマーサポートアシスタントです。入力されたテキストを正確に分類してください。",
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        }
        
        response = bedrock.invoke_model(
            modelId="xxxxx",
            body=json.dumps(body)
        )
        
        result = json.loads(response['body'].read())
        raw_category = result['content'][0]['text'].strip()
        
        # 5. 分類結果の正規化
        category = Category.OTHER.value
        for c in Category:
            if c.value in raw_category:
                category = c.value
                break
        
        # 6. タイムスタンプ更新
        timestamp = datetime.now().isoformat()
        
        # 7. DynamoDB更新
        table.update_item(
            Key={'id': inquiry_id},
            UpdateExpression="SET #cat = :cat, updatedAt = :ts",
            ExpressionAttributeNames={
                "#cat": "category"
            },
            ExpressionAttributeValues={
                ":cat": category,
                ":ts": timestamp
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Category classification successful',
                'id': inquiry_id,
                'category': category
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error classifying category: {str(e)}')
        }
