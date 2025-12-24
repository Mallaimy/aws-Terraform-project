# **AWS Highly Available Web Application Infrastructure with Terraform Overview**

This project demonstrates how to provision a highly available, scalable web application infrastructure on **AWS** using Terraform. It follows **AWS** best practices by separating public and private networking layers, using an Application Load Balancer (**ALB**), Auto Scaling Group (**ASG**), and a **NAT** Gateway for secure outbound access from private subnets.

The infrastructure is fully automated and reproducible using Infrastructure as Code (IaC).

# Architecture Summary
![Example Image](terraform%201.png)

The deployed architecture includes:

1 **VPC** with **DNS** support enabled

Multiple Availability Zones (configurable via variables)

# Public Subnets

Host the Application Load Balancer

Provide Internet access via Internet Gateway

# Private Subnets

Host **EC2** instances managed by Auto Scaling Group

No direct Internet access

Internet Gateway (**IGW**)

**NAT** Gateway

Enables outbound Internet access for private instances

Application Load Balancer (**ALB**)

Distributes **HTTP** traffic across **EC2** instances

Auto Scaling Group (**ASG**)

Automatically scales **EC2** instances

# Launch Template

Defines **EC2** configuration and user data

# Security Groups

**ALB** Security Group (**HTTP** from Internet)

Web Security Group (**HTTP** from **ALB**, **SSH** configurable)

Target Group & Listener

Health checks and traffic forwarding

# Traffic Flow Explanation

Users access the application from the Internet.

Traffic enters the Application Load Balancer in public subnets.

The **ALB** forwards traffic to **EC2** instances in private subnets.

**EC2** instances respond through the **ALB**.

For outbound traffic (updates, package installs), private instances use the **NAT** Gateway.

**NAT** Gateway routes traffic to the Internet via the Internet Gateway.

# Project Structure

. ├── main.tf              # Core infrastructure resources ├── variables.tf         # Input variables (AZs, tags, etc.) ├── terraform.tfvars     # Variable values ├── outputs.tf           # Useful outputs (optional) └── **README**.md            # Project documentation

Prerequisites

Before deploying, ensure you have:

An **AWS** account

**AWS** **CLI** installed and configured

Terraform installed (v1.5+ recommended)

A valid **EC2** key pair in **AWS**

**IAM** permissions for:

**VPC**

**EC2**

**ALB**

### Auto Scaling

**IAM** (if extended)

### Variables Example

az = [*us-east-1a*, *us-east-1b*] tags = *terraform-demo*

### Deployment Steps

### Initialize Terraform

terraform init

### Validate Configuration

terraform validate

### Preview Infrastructure Changes

terraform plan

### Apply Configuration

terraform apply

Confirm with yes when prompted.

# Auto Scaling Behavior

Minimum instances: 2

Desired capacity: 2

Maximum instances: 4

Health checks: Performed by **ALB**

Instances are automatically replaced if unhealthy.

# Security Considerations

**EC2** instances are deployed in private subnets

No direct Internet access to instances

**ALB** acts as the only public entry point

Security groups restrict traffic to required ports only

**NAT** Gateway provides controlled outbound access

Note: **SSH** access is currently open for demonstration purposes. In production, restrict **SSH** to trusted IPs or use **AWS** **SSM** Session Manager.

# Customization Ideas

You can extend this project by adding:

**HTTPS** (**ACM** + **SSL**)

S3 for static assets

CloudWatch monitoring and alarms

Terraform remote state (S3 + DynamoDB)

**AWS** Systems Manager (**SSM**)

**RDS** or DynamoDB backend

Blue/Green deployments

### Use Cases

Learning **AWS** networking and Terraform

DevOps / Cloud Engineering portfolio

Interview demonstration project

Infrastructure automation practice

Author

## Abakar Mahamat Mallah

Cloud / DevOps Engineer Terraform • **AWS** • Infrastructure Automation

If you found this project useful, feel free to ⭐ star the repository and connect on LinkedIn.
