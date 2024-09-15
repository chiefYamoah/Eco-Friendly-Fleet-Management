# Car Service Infrastructure on AWS

This project provisions the infrastructure for a car service application on AWS using EC2 instances, an Application Load Balancer (ALB), Auto Scaling Groups (ASG), and CloudWatch Alarms. The setup is fully managed using Terraform, enabling dynamic scaling based on CPU utilization while maintaining high availability and fault tolerance.

## Features

- **EC2 Instances**: Instances are launched using a predefined Amazon Machine Image (AMI) and are managed via an Auto Scaling Group.
- **Elastic Load Balancer (ALB)**: Distributes incoming traffic evenly across the EC2 instances.
- **Auto Scaling**: Automatically adjusts the number of running EC2 instances based on traffic and CPU utilization.
- **CloudWatch Alarms**: Trigger scaling policies to either add or remove instances when CPU utilization crosses predefined thresholds.
- **Security Groups**: Configured to allow inbound HTTP traffic and manage network traffic securely.

## Architecture Overview

The infrastructure consists of:

1. **AWS EC2 Instances**: Managed by an Auto Scaling Group to dynamically adjust the number of instances.
2. **Application Load Balancer (ALB)**: Ensures that traffic is balanced across all active instances.
3. **Auto Scaling Group (ASG)**: Automatically scales EC2 instances based on the CloudWatch metrics.
4. **CloudWatch Alarms**: Monitors CPU usage and triggers Auto Scaling policies to manage resources efficiently.
5. **Security Group**: Allows inbound HTTP traffic on port 80.

## Prerequisites

Before you begin, ensure that you have the following:

- **Terraform** installed on your machine. You can download it [here](https://www.terraform.io/downloads.html).
- **AWS CLI** installed and configured with credentials. You can follow the setup guide [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).
- An active **AWS Account**.
