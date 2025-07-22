#!/bin/bash

## AWS Data Science Workspace Deployment Script
# This script automates the setup of an EC2 instance and an S3 bucket for a data science workspace.

set -euo pipefail

# Default values (can be overridden by command-line arguments)
DEFAULT_INSTANCE_TYPE="t2.micro"
DEFAULT_AMI_ID="ami-0150ccaf51ab55a51" # Example: Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-1.

DEFAULT_KEY_PAIR_NAME="" # REQUIRED: Must be an existing EC2 Key Pair name in your region
DEFAULT_S3_BUCKET_NAME="my-data-science-bucket-$(date +%s)" # Unique bucket name with timestamp
DEFAULT_REPO_URL=""

# --- NEW: Hardcoded Security Group ID ---
# Using the provided security group ID. This bypasses security group creation.
# Ensure this security group exists in your target region (us-east-1) and has appropriate rules (e.g., SSH, HTTP).
DEFAULT_SECURITY_GROUP_ID="sg-0d95b4e12415f1563"
# --- END NEW ---

# --- Variables to store parsed arguments ---
INSTANCE_TYPE=$DEFAULT_INSTANCE_TYPE
AMI_ID=$DEFAULT_AMI_ID
KEY_PAIR_NAME=$DEFAULT_KEY_PAIR_NAME
S3_BUCKET_NAME=$DEFAULT_S3_BUCKET_NAME
REPO_URL=$DEFAULT_REPO_URL
CLEANUP_MODE=false
DRY_RUN=false # For future enhancements, if you want to add a dry-run mode

# --- Function Definitions ---

# Function to display script usage and help
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Automates the deployment of an AWS data science workspace (EC2 + S3)."
    echo ""
    echo "Options:"
    echo "    -i <instance_type>     EC2 instance type (default: $DEFAULT_INSTANCE_TYPE)"
    echo "    -a <ami_id>            EC2 AMI ID (default: $DEFAULT_AMI_ID). IMPORTANT: Must be valid for your region."
    echo "    -k <key_pair_name>     REQUIRED: Existing EC2 Key Pair name for SSH access."
    echo "    -b <bucket_name>       Unique S3 bucket name (default: $DEFAULT_S3_BUCKET_NAME)"
    echo "    -r <repo_url>          Git repository URL to clone and deploy (default: $DEFAULT_REPO_URL)"
    echo "    -s <security_group_id> Optional: EC2 Security Group ID to use (default: $DEFAULT_SECURITY_GROUP_ID). If not provided, the default is used and creation is skipped."
    echo "    -c                     Enable cleanup mode (deletes all created resources)."
    echo "    -h                     Display this help message."
    echo ""
    echo "Prerequisites:"
    echo "    - AWS CLI v2 installed and configured with appropriate credentials and region."
    echo "    - An existing EC2 Key Pair in your chosen AWS region."
    echo "    - Ensure your AWS_REGION environment variable is set (e.g., export AWS_REGION=us-east-1)."
    echo "    - IAM permissions for EC2 (RunInstances, CreateSecurityGroup, etc.) and S3 (CreateBucket, PutBucketPolicy, etc.)."
    echo ""
    exit 0
}

# Function to parse command-line arguments
parse_arguments() {
    # --- NEW: Add SECURITY_GROUP_ID to store argument, initialize with DEFAULT_SECURITY_GROUP_ID ---
    SECURITY_GROUP_ID=$DEFAULT_SECURITY_GROUP_ID

    while getopts "i:a:k:b:r:s:ch" opt; do
        case ${opt} in
            i ) INSTANCE_TYPE=$OPTARG ;;
            a ) AMI_ID=$OPTARG ;;
            k ) KEY_PAIR_NAME=$OPTARG ;;
            b ) S3_BUCKET_NAME=$OPTARG ;;
            r ) REPO_URL=$OPTARG ;;
            s ) SECURITY_GROUP_ID=$OPTARG ;; # --- NEW: Handle -s argument ---
            c ) CLEANUP_MODE=true ;;
            h ) display_help ;;
            \? ) echo "Invalid option: -$OPTARG" >&2; display_help ;;
            : ) echo "Invalid option: -$OPTARG requires an argument" >&2; display_help ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$KEY_PAIR_NAME" == "" ] && [ "$CLEANUP_MODE" == false ]; then
        echo "Error: Key Pair Name (-k) is required for deployment." >&2
        display_help
    fi
}

# Function to check AWS CLI configuration
check_aws_cli_config() {
    echo "Verifying AWS CLI installation and configuration..."
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed. Please install it first." >&2
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS CLI is installed but not configured with credentials." >&2
        echo "Please run 'aws configure' and provide your Access Key ID, Secret Access Key, and default region." >&2
        exit 1
    fi

    # Explicitly get AWS_REGION from environment or AWS CLI config
    # This variable will be used for S3 bucket creation logic
    if [ -z "${AWS_REGION:-}" ]; then
        echo "Warning: AWS_REGION environment variable is not set. Attempting to get from AWS CLI config." >&2
        AWS_REGION=$(aws configure get region || echo "")
        if [ -z "$AWS_REGION" ]; then
            echo "Error: AWS_REGION is not set in environment or AWS CLI config. Please set it." >&2
            exit 1
        fi
    fi
    echo "Using AWS Region: $AWS_REGION"

    echo "AWS CLI is configured and ready."
}

# --- REMOVED: create_ec2_security_group function is no longer needed as we use a fixed SG ---
# We will use the provided DEFAULT_SECURITY_GROUP_ID directly.

# Function to launch EC2 instance
# Function to launch EC2 instance
launch_ec2_instance() {
    local sg_id=$1
    echo "Launching EC2 instance ($INSTANCE_TYPE) with AMI ID: $AMI_ID..." >&2
    echo "Using Security Group ID: $sg_id" >&2

    read -r -d '' USER_DATA_SCRIPT <<EOF
#!/bin/bash
yum update -y
yum install -y httpd git
systemctl start httpd
systemctl enable httpd
# Clone the repository
git clone $REPO_URL /tmp/my-website
# Remove default Apache welcome page
rm -rf /var/www/html/*
# Copy
cp -r /tmp/my-website/. /var/www/html/
# Set permissions
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/
systemctl restart httpd
EOF

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_PAIR_NAME" \
        --security-group-ids "$sg_id" \
        --user-data "$USER_DATA_SCRIPT" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=DataScienceInstance}]" \
        --query "Instances[0].InstanceId" --output text)

    if [ -z "$INSTANCE_ID" ]; then
        echo "Error: Failed to launch EC2 instance." >&2
        exit 1
    fi
    echo "EC2 instance '$INSTANCE_ID' launched. Waiting for it to be running..." >&2

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    echo "EC2 instance is running." >&2

    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

    echo "EC2 Instance Public IP: $PUBLIC_IP" >&2
    echo "$INSTANCE_ID $PUBLIC_IP" # This line *must* output to stdout for `read`
}

# Function to create S3 bucket
create_s3_bucket() {
    echo "Creating S3 bucket '$S3_BUCKET_NAME' in region '$AWS_REGION'..."
    # S3 bucket names must be globally unique
    if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
        echo "Warning: S3 bucket '$S3_BUCKET_NAME' already exists. Skipping creation."
    else
        # --- FIX FOR INVALID LOCATION CONSTRAINT ERROR ---
        # us-east-1 does not require LocationConstraint
        if [ "$AWS_REGION" == "us-east-1" ]; then
            aws s3api create-bucket \
                --bucket "$S3_BUCKET_NAME" \
                --region "$AWS_REGION" >/dev/null
        else
            aws s3api create-bucket \
                --bucket "$S3_BUCKET_NAME" \
                --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null
        fi
        # --- END FIX ---
        echo "S3 bucket '$S3_BUCKET_NAME' created."
    fi
}

# Function to configure S3 bucket (block public access, enable versioning)
configure_s3_bucket() {
    echo "Configuring S3 bucket '$S3_BUCKET_NAME'..."

    # Block all public access
    echo "Blocking all public access for S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$S3_BUCKET_NAME" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" >/dev/null
    echo "Public access blocked for '$S3_BUCKET_NAME'."

    # Enable Versioning
    echo "Enabling versioning for S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$S3_BUCKET_NAME" \
        --versioning-configuration Status=Enabled >/dev/null
    echo "Versioning enabled for '$S3_BUCKET_NAME'."
}

# Function to verify deployment
verify_deployment() {
    echo ""
    echo "--- Verifying Deployment Status ---"
    echo "Checking EC2 instance status..."
    local instance_status=$(aws ec2 describe-instances --instance-ids "$EC2_INSTANCE_ID" --query "Reservations[0].Instances[0].State.Name" --output text)
    if [ "$instance_status" == "running" ]; then
        echo "EC2 instance '$EC2_INSTANCE_ID' is running."
        echo "Access your website at: http://$EC2_PUBLIC_IP"
    else
        echo "EC2 instance '$EC2_INSTANCE_ID' is in state: $instance_status. Check AWS Console for details." >&2
    fi

    echo "Checking S3 bucket status..."
    if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" &>/dev/null; then
        echo "S3 bucket '$S3_BUCKET_NAME' exists and is accessible."
    else
        echo "Error: S3 bucket '$S3_BUCKET_NAME' does not exist or is not accessible." >&2
    fi
    echo "--- Verification Complete ---"
}

# Function to clean up all created resources
cleanup_resources() {
    echo ""
    echo "--- Starting Cleanup Process ---"

    # Terminate EC2 Instance
    if [ -n "${EC2_INSTANCE_ID:-}" ]; then
        echo "Terminating EC2 instance '$EC2_INSTANCE_ID'..."
        aws ec2 terminate-instances --instance-ids "$EC2_INSTANCE_ID" >/dev/null
        echo "Waiting for EC2 instance to be terminated..."
        aws ec2 wait instance-terminated --instance-ids "$EC2_INSTANCE_ID"
        echo "EC2 instance '$EC2_INSTANCE_ID' terminated."
    else
        echo "No EC2 instance ID found for cleanup."
    fi

    # Delete S3 Bucket (must be empty first)
    if [ -n "${S3_BUCKET_NAME:-}" ]; then
        echo "Emptying S3 bucket '$S3_BUCKET_NAME'..."
        # Delete all objects and versions
        aws s3 rm "s3://$S3_BUCKET_NAME" --recursive --include-all-versions >/dev/null
        echo "S3 bucket '$S3_BUCKET_NAME' emptied."

        echo "Deleting S3 bucket '$S3_BUCKET_NAME'..."
        aws s3api delete-bucket --bucket "$S3_BUCKET_NAME" >/dev/null
        echo "S3 bucket '$S3_BUCKET_NAME' deleted."
    else
        echo "No S3 bucket name found for cleanup."
    fi

    # --- NEW: Conditional Security Group Deletion ---
    # Only attempt to delete the security group if it was created by this script.
    # If a fixed SG ID was used, we assume it's pre-existing and should not be deleted.
    if [ -n "${EC2_SG_ID:-}" ] && [ "$EC2_SG_ID" != "$DEFAULT_SECURITY_GROUP_ID" ]; then
        echo "Deleting Security Group '$EC2_SG_ID'..."
        # It might take a moment for the SG to detach from the instance
        sleep 5
        if aws ec2 delete-security-group --group-id "$EC2_SG_ID" 2>/dev/null; then
            echo "Security Group '$EC2_SG_ID' deleted."
        else
            echo "Warning: Failed to delete Security Group '$EC2_SG_ID'. It might still be in use or require manual deletion." >&2
        fi
    else
        echo "Security Group '$DEFAULT_SECURITY_GROUP_ID' was provided, not created by this script. Skipping deletion."
    fi
    # --- END NEW ---

    echo "--- Cleanup Process Complete ---"
}

# --- Main Execution Flow ---

# Parse arguments first
parse_arguments "$@"

# If cleanup mode is enabled, run cleanup and exit
if [ "$CLEANUP_MODE" == true ]; then
    echo "Running in cleanup mode."
    # Attempt to load previous deployment info for cleanup
    if [ -f "deployment_info.txt" ]; then
        source deployment_info.txt
        # Ensure EC2_SG_ID is set for cleanup, even if it was the default
        # If not present in file, use the default from script if applicable.
        : ${EC2_SG_ID:=$DEFAULT_SECURITY_GROUP_ID}
        cleanup_resources
    else
        echo "Error: No 'deployment_info.txt' found. Cannot perform automated cleanup without deployment details." >&2
        echo "Please provide EC2_INSTANCE_ID, S3_BUCKET_NAME, and EC2_SG_ID as environment variables or manually delete resources." >&2
        exit 1
    fi
    exit 0
fi

# Check AWS CLI configuration before proceeding with deployment
check_aws_cli_config

echo "--- Starting AWS Data Science Workspace Deployment ---"

# --- MODIFIED: Removed Security Group Creation Call ---
# We are now using the fixed `DEFAULT_SECURITY_GROUP_ID` or the one passed via `-s`.
# The `EC2_SG_ID` variable will now directly store this value.
EC2_SG_ID=$SECURITY_GROUP_ID
echo "Using provided Security Group ID: $EC2_SG_ID"
# --- END MODIFIED ---

# 2. Launch EC2 Instance
# The output of launch_ec2_instance is "INSTANCE_ID PUBLIC_IP"
read -r EC2_INSTANCE_ID EC2_PUBLIC_IP <<< $(launch_ec2_instance "$EC2_SG_ID")

# 3. Create S3 Bucket
create_s3_bucket

# 4. Configure S3 Bucket
configure_s3_bucket

# Save deployment info for cleanup
echo "Saving deployment information to deployment_info.txt..."
echo "EC2_INSTANCE_ID=$EC2_INSTANCE_ID" > deployment_info.txt
echo "EC2_PUBLIC_IP=$EC2_PUBLIC_IP" >> deployment_info.txt
echo "S3_BUCKET_NAME=$S3_BUCKET_NAME" >> deployment_info.txt
echo "EC2_SG_ID=$EC2_SG_ID" >> deployment_info.txt # Save the used SG ID for cleanup
echo "Deployment information saved. Keep 'deployment_info.txt' for cleanup."

# 5. Verify Deployment
verify_deployment

echo "--- Deployment Complete! ---"
echo "To clean up all resources later, run: $0 -c"
