# AWS CLI Setup and Secure Authentication

## Project Overview

This README documents the complete process of setting up secure authentication to AWS API using AWS CLI on a Linux operating system. The project focuses on creating the necessary AWS account infrastructure for programmatic access to EC2 and S3 services.

## Prerequisites

- Linux operating system
- Terminal access with sudo privileges
- Active AWS account
- Internet connection

## Table of Contents

1. [AWS Account Configuration](#aws-account-configuration)
2. [AWS CLI Installation](#aws-cli-installation)
3. [AWS CLI Configuration](#aws-cli-configuration)
4. [Testing the Setup](#testing-the-setup)
5. [Understanding APIs](#understanding-apis)
6. [Security Considerations](#security-considerations)

## AWS Account Configuration

### Step 1: Create an IAM Role

1. Navigate to the AWS Management Console
2. Go to IAM (Identity and Access Management) service
3. Click on "Roles" in the left sidebar
4. Click "Create role"
5. Select "AWS service" as the trusted entity
6. Choose the appropriate service that will assume this role
7. Name the role appropriately (e.g., `AutomationRole`)

### Step 2: Create an IAM Policy

1. In the IAM console, click on "Policies" in the left sidebar
2. Click "Create policy"
3. Use the JSON editor to create a policy granting full access to EC2 and S3:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
```

4. Name the policy (e.g., `EC2S3FullAccessPolicy`)
5. Add a description and create the policy

### Step 3: Create an IAM User

1. In the IAM console, click on "Users" in the left sidebar
2. Click "Create user"
3. Set the username as `automation_user`
4. Select "Programmatic access" for access type
5. Proceed to the next step without adding the user to any groups initially

### Step 4: Assign User to IAM Role

1. After creating the user, go to the user's details page
2. Click on the "Permissions" tab
3. Click "Add permissions"
4. Select "Attach existing policies directly"
5. Search for and attach the role created in Step 1

### Step 5: Attach IAM Policy to User

1. In the user's permissions tab
2. Click "Add permissions" again
3. Select "Attach existing policies directly"
4. Search for and select the `EC2S3FullAccessPolicy` created in Step 2
5. Click "Next" and then "Add permissions"

### Step 6: Create Programmatic Access Credentials

1. In the user's details page, click on the "Security credentials" tab
2. Click "Create access key"
3. Select "Command Line Interface (CLI)" as the use case
4. Confirm and create the access key
5. **Important**: Download and securely store both:
   - Access Key ID
   - Secret Access Key

**Security Note**: These credentials provide full access to your EC2 and S3 resources. Store them securely and never share them publicly.

## AWS CLI Installation

### For Linux Systems

1. **Download the AWS CLI version 2 installation package:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

2. **Unzip the downloaded package:**

```bash
unzip awscliv2.zip
```

3. **Install the AWS CLI:**

```bash
sudo ./aws/install
```

4. **Verify the installation:**

```bash
aws --version
```

You should see output similar to:
```
aws-cli/2.x.x Python/3.x.x Linux/x.x.x exe/x86_64.x
```

## AWS CLI Configuration

### Configure AWS Credentials

1. **Initialize the AWS CLI configuration:**

```bash
aws configure
```

2. **Enter the required information when prompted:**

```
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Configuration Details:**
- **Access Key ID**: The key generated in Step 6 of AWS Account Configuration
- **Secret Access Key**: The secret key generated in Step 6 of AWS Account Configuration
- **Default region**: Choose based on your geographic location or requirements (e.g., `us-east-1`, `eu-west-1`)
- **Output format**: `json` is recommended for programmatic use

### Configuration File Locations

The AWS CLI stores configuration in these files:
- Credentials: `~/.aws/credentials`
- Configuration: `~/.aws/config`

## Testing the Setup

### Test AWS CLI Connectivity

1. **List all AWS regions:**

```bash
aws ec2 describe-regions --output table
```

Expected output should display a formatted table of all AWS regions.

2. **Test S3 access by listing buckets:**

```bash
aws s3 ls
```

3. **Test EC2 access by describing instances:**

```bash
aws ec2 describe-instances
```

If these commands execute without authentication errors, your setup is successful.

## Understanding APIs

### What is an API?

An **Application Programming Interface (API)** is a set of protocols and tools that allows different software applications to communicate with each other. In the AWS context:

- **AWS API**: Enables scripts and tools like AWS CLI to interact with AWS services programmatically
- **API Calls**: Structured requests that AWS services can understand and act upon
- **Programmatic Access**: Ability to create, modify, and delete AWS resources through code rather than the web console

### AWS API Benefits

1. **Automation**: Automate repetitive tasks and resource management
2. **Integration**: Integrate AWS services into applications and workflows
3. **Scalability**: Manage resources at scale through scripts and programs
4. **Consistency**: Ensure consistent configurations across environments

## Security Considerations

### Best Practices

1. **Credential Security**:
   - Never commit credentials to version control
   - Use environment variables or credential files with appropriate permissions
   - Regularly rotate access keys

2. **Principle of Least Privilege**:
   - Grant only necessary permissions
   - Review and audit permissions regularly
   - Use IAM roles instead of user credentials when possible

3. **Monitoring**:
   - Enable CloudTrail for API call logging
   - Monitor unusual activity in your AWS account
   - Set up billing alerts

### File Permissions

Ensure your AWS credentials have appropriate permissions:

```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**:
   - Verify IAM policies are correctly attached
   - Check that the user has necessary permissions

2. **Installation Issues**:
   - Ensure you have sudo privileges for installation
   - Verify curl and unzip are installed

3. **Configuration Issues**:
   - Double-check access keys for typos
   - Verify the selected region is correct

### Verification Commands

```bash
# Check AWS CLI installation
aws --version

# Verify configuration
aws configure list

# Test basic connectivity
aws sts get-caller-identity

# Test with basic command to list AWS Region
aws ec2 describe-regions --output table
```

## Output of AWS Regions in Tabular form

![List of AWS Regions](img/image.png)

## Next Steps

With AWS CLI properly configured, you can now:

1. Create and manage EC2 instances programmatically
2. Manage S3 buckets and objects
3. Develop automation scripts for AWS resource management
4. Integrate AWS services into your applications

## Conclusion

This project successfully demonstrates the setup of secure authentication to AWS API using AWS CLI on Linux. The configuration enables programmatic access to AWS services while following security best practices for credential management and access control.
