# Remote state configuration using S3
terraform {
  backend "s3" {
    bucket       = "redbus-terraform-state"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Note: Before using this backend, create the S3 bucket and DynamoDB table:
#
# aws s3api create-bucket --bucket redbus-terraform-state --region us-east-1
# aws s3api put-bucket-versioning --bucket redbus-terraform-state --versioning-configuration Status=Enabled
# aws s3api put-bucket-encryption --bucket redbus-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# aws dynamodb create-table \
#   --table-name redbus-terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
