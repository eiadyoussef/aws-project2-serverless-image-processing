import json
import os
import boto3
import urllib.parse
from datetime import datetime, timezone

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

PROCESSED_BUCKET = os.environ["PROCESSED_BUCKET"]
TABLE_NAME = os.environ["TABLE_NAME"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    for record in event.get("Records", []):
        body = json.loads(record["body"])

        # Ignore S3 notification test events
        if body.get("Event") == "s3:TestEvent":
            print("Ignoring S3 test event")
            continue

        # Process normal S3 notification events
        for s3_record in body.get("Records", []):
            source_bucket = s3_record["s3"]["bucket"]["name"]

            source_key = urllib.parse.unquote_plus(
                s3_record["s3"]["object"]["key"]
            )

            filename = source_key.split("/")[-1]
            processed_key = f"processed/{filename}"

            print(
                f"Processing {source_bucket}/{source_key}"
            )

            s3.copy_object(
                Bucket=PROCESSED_BUCKET,
                CopySource={
                    "Bucket": source_bucket,
                    "Key": source_key
                },
                Key=processed_key,
                Metadata={
                    "processed": "true",
                    "processed-by": "aws-lambda"
                },
                MetadataDirective="REPLACE"
            )

            image_id = source_key

            table.put_item(
                Item={
                    "image_id": image_id,
                    "source_bucket": source_bucket,
                    "source_key": source_key,
                    "processed_bucket": PROCESSED_BUCKET,
                    "processed_key": processed_key,
                    "status": "PROCESSED",
                    "processed_at": datetime.now(
                        timezone.utc
                    ).isoformat()
                }
            )

            print(
                f"Successfully processed {source_key}"
            )

    return {
        "statusCode": 200,
        "body": json.dumps(
            "Image processing completed"
        )
    }