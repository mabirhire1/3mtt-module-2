# AWS Cloud Manager Shell Script

## Overview

This project demonstrates the creation of a dynamic shell script (`aws_cloud_manager.sh`) that manages cloud infrastructure across different environments using environment variables and positional parameters. The script showcases best practices for environment-specific deployments in DevOps workflows.

## Learning Objectives

- Understand the difference between Infrastructure Environments and Environment Variables
- Create dynamic shell scripts using environment variables
- Implement positional parameters for runtime flexibility
- Add input validation and error handling
- Practice DevOps best practices for multi-environment deployments

## Prerequisites

- Basic understanding of shell scripting
- Access to a terminal (Mac Terminal, Ubuntu, or EC2 instance)
- Text editor for creating shell scripts

## Environment Setup

Choose one of the following setups:

### Option 1: Linux Users (Your Setup)
- Open your Linux terminal (Ctrl+Alt+T or search for Terminal)

### Option 2: Mac Users
- Open Mac Terminal

### Option 3: Windows Users
- Login to Ubuntu desktop in VirtualBox
- Open terminal

### Option 4: Cloud Users
- Spin up an EC2 instance named "local"
- SSH into the instance

## Implementation Steps

### Step 1: Create the Basic Script

Create a new file named `aws_cloud_manager.sh`:

```bash
#!/bin/bash

# Checking and acting on the environment variable
if [ "$ENVIRONMENT" == "local" ]; then
    echo "Running script for local Environment..."
# Commands for local environment
elif [ "$ENVIRONMENT" == "testing" ]; then
    echo "Running script for Testing Environment..."
# Commands for testing environment
elif [ "$ENVIRONMENT" == "production" ]; then
    echo "Running script for Production Environment..."
# Commands for production environment
else
    echo "No environment specified or recognized."
    exit 2
fi
```

### Step 2: Set Execute Permissions

Make the script executable on your Linux system:

```bash
chmod +x aws_cloud_manager.sh
```

Note: On Linux, you typically don't need `sudo` for this operation unless you're in a system directory.

### Step 3: Test with Environment Variables

Test the script using environment variables:

```bash
# Test without setting environment variable (should go to else block which outputs "No environment specified or recognized.")
./aws_cloud_manager.sh

# Set environment variable and test
export ENVIRONMENT=production
./aws_cloud_manager.sh
```

Expected output:
```
Running script for Production Environment...
```

### Step 4: Implement Positional Parameters

Update the script to use positional parameters instead of hard-coded values:

```bash
#!/bin/bash

# Initialize environment variable from first argument
ENVIRONMENT=$1

# Checking and acting on the environment variable
if [ "$ENVIRONMENT" == "local" ]; then
    echo "Running script for local Environment..."
elif [ "$ENVIRONMENT" == "testing" ]; then
    echo "Running script for Testing Environment..."
elif [ "$ENVIRONMENT" == "production" ]; then
    echo "Running script for Production Environment..."
else
    echo "No environment specified or recognized."
    exit 2
fi
```

### Step 5: Add Argument Validation

Enhance the script with input validation:

```bash
#!/bin/bash

# Checking the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

# Accessing the first argument
ENVIRONMENT=$1

# Acting based on the argument value
if [ "$ENVIRONMENT" == "local" ]; then
    echo "Running script for Local Environment..."
elif [ "$ENVIRONMENT" == "testing" ]; then
    echo "Running script for Testing Environment..."
elif [ "$ENVIRONMENT" == "production" ]; then
    echo "Running script for Production Environment..."
else
    echo "Invalid environment specified. Please use 'local', 'testing', or 'production'."
    exit 2
fi
```

## Usage Examples

### Basic Usage
```bash
# Run for local environment
./aws_cloud_manager.sh local

# Run for testing environment
./aws_cloud_manager.sh testing

# Run for production environment
./aws_cloud_manager.sh production
```

### Error Handling Examples
```bash
# No arguments provided
./aws_cloud_manager.sh
# Output: Usage: ./aws_cloud_manager.sh <environment>

# Invalid environment
./aws_cloud_manager.sh staging
# Output: Invalid environment specified. Please use 'local', 'testing', or 'production'.

# Too many arguments
./aws_cloud_manager.sh local testing
# Output: Usage: ./aws_cloud_manager.sh <environment>
```

## Key Concepts Explained

### Infrastructure Environments
- **Local Environment**: Development setup (VirtualBox + Ubuntu)
- **Testing Environment**: AWS Account 1 for testing
- **Production Environment**: AWS Account 2 for live deployment

### Environment Variables
Key-value pairs that differ across environments:
- `DB_URL`: Database connection URL
- `DB_USER`: Database username
- `DB_PASS`: Database password

### Positional Parameters
- `$0`: Script name
- `$1`: First argument
- `$2`: Second argument
- `$#`: Number of arguments passed

## Best Practices Implemented

1. **Input Validation**: Check number of arguments before processing
2. **Error Handling**: Provide clear error messages and appropriate exit codes
3. **Dynamic Configuration**: Use positional parameters instead of hard-coded values
4. **Clear Documentation**: Provide usage instructions when errors occur
5. **Environment Separation**: Maintain distinct logic for different environments

## Testing the Script

### Test Cases
1. **Valid Environments**: Test with 'local', 'testing', and 'production'
2. **Invalid Environment**: Test with unsupported environment name
3. **No Arguments**: Test without providing any arguments
4. **Multiple Arguments**: Test with more than one argument

### Expected Behaviors
- Script should execute appropriate logic for valid environments
- Script should exit with code 1 for incorrect number of arguments
- Script should exit with code 2 for invalid environment names
- Script should provide helpful usage messages for errors

## Extending the Script

The script can be extended to include:
- Multiple positional parameters (e.g., number of instances)
- AWS CLI commands for actual cloud resource management
- Configuration file support
- Logging functionality
- Backup and rollback capabilities

## Troubleshooting

### Common Issues
1. **Permission Denied**: Ensure script has execute permissions (`chmod +x`)
2. **Command Not Found**: Verify script is in current directory or PATH
3. **Environment Variable Conflicts**: Clear existing environment variables if needed

### Debug Mode
Add debug output to troubleshoot:
```bash
#!/bin/bash
set -x  # Enable debug mode
```

## Conclusion

This project demonstrates fundamental DevOps concepts including environment management, shell scripting best practices, and dynamic configuration handling. The `aws_cloud_manager.sh` script provides a foundation for building more complex infrastructure automation tools.

## Summary

Through this mini project, I learned the critical distinction between infrastructure environments (physical/virtual setups like local, testing, and production) and environment variables (configuration key-value pairs). I successfully created a dynamic shell script that uses positional parameters to accept runtime arguments, implemented proper input validation to ensure script reliability, and applied DevOps best practices for managing multi-environment deployments. The hands-on experience reinforced the importance of avoiding hard-coded values in favor of flexible, parameterized solutions that can adapt to different deployment contexts while maintaining code quality through error handling and user guidance.