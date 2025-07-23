# AWS Auto Scaling with Application Load Balancer (ALB) using Launch Template

## Project Overview

This project demonstrates the implementation of automatic scaling of EC2 instances in AWS using an Application Load Balancer (ALB) and Launch Template. The setup ensures optimal resource utilization and maintains application performance during varying workloads.

## Architecture Components

- **Launch Template**: Defines the configuration for EC2 instances
- **Auto Scaling Group**: Manages the desired number of EC2 instances
- **Application Load Balancer (ALB)**: Distributes incoming traffic across instances
- **Scaling Policies**: Rules that determine when to scale in or out based on demand

## Prerequisites

- AWS Account with appropriate permissions
- Basic understanding of EC2, ALB, and Auto Scaling concepts
- Access to AWS Management Console

## Implementation Steps

### Task 1: Create Launch Template

#### Step 1.1: Access Launch Templates
1. Log in to the AWS Management Console
2. Navigate to the **EC2 service**
3. In the left navigation pane, click on **"Launch Templates"**

#### Step 1.2: Create New Template
1. Click the **"Create launch template"** button
2. Configure the following settings:
   - **Template name**: Provide a descriptive name
   - **AMI**: Select appropriate Amazon Machine Image
   - **Instance type**: Choose based on your requirements (e.g., t3.micro for testing)
   - **Key pair**: Select existing key pair or create new one
   - **Security groups**: Configure appropriate security groups
   - **User data**: Add any initialization scripts if needed

#### Step 1.3: Save Template
1. Review all configurations
2. Click **"Create launch template"**
3. Note the Launch Template ID for future reference

### Task 2: Set Up Auto Scaling Group

#### Step 2.1: Navigate to Auto Scaling Groups
1. In the AWS Management Console, stay in the EC2 service
2. In the left navigation pane, click on **"Auto Scaling Groups"**

#### Step 2.2: Create Auto Scaling Group
1. Click the **"Create Auto Scaling group"** button
2. **Step 1 - Choose launch template**:
   - Select **"Use Launch Template"**
   - Choose the Launch Template created in Task 1
   - Click **"Next"**

#### Step 2.3: Configure Group Settings
1. **Step 2 - Configure settings**:
   - **Auto Scaling group name**: Provide descriptive name
   - **VPC**: Select appropriate VPC
   - **Availability Zones and subnets**: Choose multiple AZs for high availability
   - Click **"Next"**

#### Step 2.4: Set Capacity and Scaling
1. **Step 3 - Configure advanced options**:
   - **Group size**: 
     - Desired capacity: 2
     - Minimum capacity: 1
     - Maximum capacity: 5
   - **Scaling policies**: Will be configured in Task 3
   - Click **"Next"**

#### Step 2.5: Additional Configurations
1. **Step 4 - Configure group size and scaling policies** (if not done in previous step)
2. **Step 5 - Add notifications** (optional)
3. **Step 6 - Add tags** (optional but recommended)
4. **Step 7 - Review** and click **"Create Auto Scaling group"**

### Task 3: Configure Scaling Policies

#### Step 3.1: Access Scaling Policies
1. Select your Auto Scaling group from the list
2. Navigate to the **"Scaling policies"** tab 
3. Click **"Create scaling policy"**

#### Step 3.2: Create Scale-Out Policy
1. **Policy type**: Target tracking scaling policy (recommended) or Step scaling
2. **Scaling policy name**: "Scale-Out-Policy"
3. **Metric type**: 
   - Average CPU Utilization
   - Target value: 70%
4. **Instance warm-up**: 300 seconds
5. Click **"Create"**

#### Step 3.3: Create Scale-In Policy
1. Click **"Create scaling policy"** again
2. Configure similar settings for scaling in:
   - **Policy name**: "Scale-In-Policy"
   - **Scale in when**: CPU utilization < 30%
3. Click **"Create"**

### Task 4: Attach ALB to Auto Scaling Group

#### Step 4.1: Access Load Balancing Configuration
1. In your Auto Scaling group, go to the **"Details"** tab
2. Click **"Edit"** in the Load balancing section

#### Step 4.2: Configure Load Balancer
1. **Load balancer type**: Application Load Balancer
2. **Choose from existing load balancers**: Select your existing ALB
   - If no ALB exists, create one first in the EC2 Load Balancers section
3. **Target group**: Select or create appropriate target group
4. **Health check type**: ELB
5. **Health check grace period**: 300 seconds
6. Click **"Update"**

### Task 5: Test Auto Scaling

#### Step 5.1: Generate Load for Testing
1. **SSH into one of the running instances**:
   ```bash
   ssh -i your-key.pem ec2-user@instance-public-ip
   ```

2. **Install stress testing tool**:
   ```bash
   sudo amazon-linux-extras install epel -y
   sudo yum install stress -y
   ```

3. **Generate CPU load**:
   ```bash
   stress -c 4
   ```

#### Step 5.2: Monitor Scaling Activity
1. In the AWS Console, navigate to your Auto Scaling group
2. Go to the **"Activity"** tab to monitor scaling activities
3. Check the **"Monitoring"** tab to view metrics
4. Observe that new instances are launched when CPU utilization exceeds 70%

#### Step 5.3: Test Scale-In
1. Stop the stress test:
   ```bash
   # Press Ctrl+C to stop the stress command
   ```
2. Wait for CPU utilization to drop below 30%
3. Monitor the Auto Scaling group for scale-in activities

## Verification Steps

### 1. Verify Launch Template
- [ ] Launch Template created successfully
- [ ] Template contains correct AMI and instance type
- [ ] Security groups and networking configured properly

### 2. Verify Auto Scaling Group
- [ ] Auto Scaling Group created with correct Launch Template
- [ ] Desired, minimum, and maximum capacities set appropriately
- [ ] Instances launched in multiple Availability Zones

### 3. Verify Scaling Policies
- [ ] Scale-out policy triggers when CPU > 70%
- [ ] Scale-in policy triggers when CPU < 30%
- [ ] Scaling activities visible in Activity tab

### 4. Verify ALB Integration
- [ ] ALB attached to Auto Scaling Group
- [ ] Target group configured correctly
- [ ] Health checks passing for instances
- [ ] Traffic distributed across instances

### 5. Verify Load Testing
- [ ] Stress tool installed successfully
- [ ] High CPU load triggers scale-out
- [ ] Reduced load triggers scale-in
- [ ] All activities logged in Auto Scaling Group

## Monitoring and Troubleshooting

### Key Metrics to Monitor
- **CPU Utilization**: Primary metric for scaling decisions
- **Instance Health**: Ensure instances pass health checks
- **Scaling Activities**: Monitor successful/failed scaling events
- **ALB Target Health**: Verify instances are healthy in target group

### Common Issues and Solutions
1. **Instances not scaling**: Check scaling policy configuration and CloudWatch metrics
2. **Health check failures**: Verify security groups and application health endpoints
3. **ALB not routing traffic**: Confirm target group registration and health checks
4. **Permission errors**: Ensure Auto Scaling service role has necessary permissions

## Best Practices

1. **Use multiple Availability Zones** for high availability
2. **Set appropriate scaling thresholds** to avoid unnecessary scaling
3. **Configure health checks properly** to ensure only healthy instances receive traffic
4. **Use CloudWatch alarms** for additional monitoring
5. **Tag resources appropriately** for better management and cost tracking
6. **Test scaling policies** thoroughly before production deployment

## Cleanup

To avoid unnecessary charges, clean up resources after testing:

1. **Delete Auto Scaling Group**:
   - Set desired capacity to 0
   - Wait for instances to terminate
   - Delete the Auto Scaling Group

2. **Delete Launch Template**:
   - Navigate to Launch Templates
   - Delete the created template

3. **Clean up ALB and Target Groups** (if created for this project)

## Conclusion

This project demonstrates the implementation of a scalable architecture using AWS Auto Scaling with Application Load Balancer. The setup ensures automatic scaling based on demand while maintaining high availability and optimal resource utilization.

## Key Learnings

- **Launch Templates** provide consistency and version control for instance configurations
- **Auto Scaling Groups** automatically manage instance capacity based on defined policies
- **Application Load Balancers** distribute traffic and provide health checking capabilities
- **Scaling Policies** enable automatic response to changing demand patterns
- **Proper monitoring** is essential for understanding scaling behavior and troubleshooting issues

## Challenges and Fixes 

1. **Instances Showing as "Unhealthy" in Target Group**
**Symptoms:**
   - Targets appear as "Unhealthy" in target group
   - Traffic not reaching instances
   - 502/503 errors from load balancer

**Common Causes & Fixes:**
   - Security Group Issues
   - Health Check Path Issues
   - Application Not Running

2. **Load Balancer Returns 502/504 Gateway Errors**
**Symptoms:**
   - Intermittent 502 Bad Gateway errors
   - 504 Gateway Timeout errors

**Fixes:**
   - Increase Health Check Settings
   - Fix Application Response Time

3. **Instances Not Scaling Out During High Load**
**Symptoms:**
   - CPU high but no new instances launched
   - Scaling policies not triggering

**Common Causes & Fixes:**
   - Insufficient Capacity
   - CloudWatch Alarm Issues
   - Instance Launch Failures

4. **Launch Template Issues**
**Symptoms:**
   - Instances fail to launch
   - Launch template errors

**Common Issues & Fixes:**
   - Invalid AMI.
   - Security Group Issues.
