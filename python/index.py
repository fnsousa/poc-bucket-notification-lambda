import json

def lambda_handler(event, context):
    message = event["Records"][0]["s3"]["object"]["key"]
    print('Filename upload: ', message)
    return {
        'message' : message
    }
