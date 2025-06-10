# A script to initialize the Terraform state store in AWS. Meant to be run exactly once.
#!/bin/bash
set -e

aws s3api create-bucket \
  --bucket experiments-infra-state \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2
# {
#     "Location": "http://experiments-infra-state.s3.amazonaws.com/"
# } 

aws s3api put-bucket-versioning \
  --bucket experiments-infra-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket experiments-infra-state \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# {
#     "TableDescription": {
#         "AttributeDefinitions": [
#             {
#                 "AttributeName": "LockID",
#                 "AttributeType": "S"
#             }
#         ],
#         "TableName": "terraform-locks",
#         "KeySchema": [
#             {
#                 "AttributeName": "LockID",
#                 "KeyType": "HASH"
#             }
#         ],
#         "TableStatus": "CREATING",
#         "CreationDateTime": "2025-06-10T00:15:17.499000-07:00",
#         "ProvisionedThroughput": {
#             "NumberOfDecreasesToday": 0,
#             "ReadCapacityUnits": 0,
#             "WriteCapacityUnits": 0
#         },
#         "TableSizeBytes": 0,
#         "ItemCount": 0,
#         "TableArn": "arn:aws:dynamodb:us-east-1:396724649279:table/terraform-loc
# ks",
#         "TableId": "e8a9556f-5f4a-4a1f-a2c7-86cd900384bd",
#         "BillingModeSummary": {
#             "BillingMode": "PAY_PER_REQUEST"
#         },
#         "DeletionProtectionEnabled": false
#     }
# }