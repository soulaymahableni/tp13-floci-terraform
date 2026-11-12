#!/usr/bin/env bash
# Partie 4 : création du bucket de state (versionné, chiffré, non public).
set -euo pipefail
export AWS_PROFILE=${AWS_PROFILE:-floci}

aws s3api create-bucket --bucket tp13-tfstate
aws s3api put-bucket-versioning --bucket tp13-tfstate \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket tp13-tfstate \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' || true
aws s3api put-public-access-block --bucket tp13-tfstate \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true || true

aws s3api get-bucket-versioning --bucket tp13-tfstate
