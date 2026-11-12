#!/usr/bin/env bash
# Partie 1 : AWS CLI contre Floci. À lancer depuis la racine du projet.
# Capture : floci-cli.png
set -euo pipefail

aws configure set aws_access_key_id test --profile floci
aws configure set aws_secret_access_key test --profile floci
aws configure set region us-east-1 --profile floci
aws configure set endpoint_url http://localhost:4566 --profile floci
export AWS_PROFILE=floci

echo "== STS =="
aws sts get-caller-identity

echo "== S3 =="
aws s3 mb s3://tp13-demo || true
echo "Bonjour Floci" > hello.txt
aws s3 cp hello.txt s3://tp13-demo/
aws s3 ls s3://tp13-demo/
aws s3 cp s3://tp13-demo/hello.txt -

echo "== SQS =="
QURL=$(aws sqs create-queue --queue-name tp13-demo --query QueueUrl --output text)
echo "QURL=$QURL"
aws sqs send-message --queue-url "$QURL" --message-body '{"event":"test"}'
aws sqs receive-message --queue-url "$QURL"

echo "== DynamoDB =="
aws dynamodb create-table --table-name visits \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null || true
aws dynamodb put-item --table-name visits \
  --item '{"id":{"S":"v1"},"page":{"S":"/accueil"},"user":{"S":"ada"}}'
aws dynamodb put-item --table-name visits \
  --item '{"id":{"S":"v2"},"page":{"S":"/contact"},"user":{"S":"alan"}}'
aws dynamodb scan --table-name visits

echo "== Secrets Manager =="
aws secretsmanager create-secret --name tp13/demo/api-key \
  --secret-string 'sk-demo-123456' >/dev/null || true
aws secretsmanager get-secret-value --secret-id tp13/demo/api-key

echo "== Lambda =="
(cd lambda && rm -f function.zip && zip -q function.zip index.mjs)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws lambda create-function --function-name hello --runtime nodejs22.x \
  --handler index.handler --zip-file fileb://lambda/function.zip \
  --role arn:aws:iam::$ACCOUNT:role/lambda-role >/dev/null || true
sleep 3
aws lambda invoke --function-name hello --payload '{"name":"Ada"}' \
  --cli-binary-format raw-in-base64-out out.json && cat out.json && echo

echo
echo "Pour la suite : export QURL=$QURL"
