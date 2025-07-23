#!/bin/bash

AWS_REGION="us-east-1"  # Change this if needed

# Function to create ec2 instance
create_ec2_instance() {
  echo "Provisioning EC2 instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name your-key-name-here \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MiniProjectInstance}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region "$AWS_REGION")
  echo "Instance created with ID: $INSTANCE_ID"
}

# Function to create departmental S3 buckets
create_s3_buckets() {
  echo "Creating S3 buckets for departments..."

  departments=("marketing" "sales" "hr" "operations" "media")

  for dept in "${departments[@]}"; do
    bucket_name="company-${dept}-bucket-$(date +%s)"
    echo "Creating bucket: $bucket_name"

    if [ "$AWS_REGION" == "us-east-1" ]; then
      aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$AWS_REGION"
    else
      aws s3api create-bucket \
        --bucket "$bucket_name" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi

    aws s3api wait bucket-exists --bucket "$bucket_name"

    aws s3api put-bucket-versioning \
      --bucket "$bucket_name" \
      --versioning-configuration Status=Enabled

    aws s3api put-public-access-block \
      --bucket "$bucket_name" \
      --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
      }'

    echo "$bucket_name setup complete."
  done
}

# Run both functions
create_ec2_instance
create_s3_buckets
