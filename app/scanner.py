import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    buckets = s3.list_buckets()['Buckets']
    report = []

    for bucket in buckets:
        name = bucket['Name']
        try:
            # Check if public access is blocked (a core DevSecOps task)
            status = s3.get_public_access_block(Bucket=name)
            is_secure = all(status['PublicAccessBlockConfiguration'].values())
        except:
            is_secure = False
        report.append({"bucket": name, "fully_private": is_secure})
    
    print(f"Audit Result: {json.dumps(report)}")
    return {'statusCode': 200, 'body': json.dumps(report)}