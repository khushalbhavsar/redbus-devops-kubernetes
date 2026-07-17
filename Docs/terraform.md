# 🏗️ Terraform Infrastructure Documentation

This document provides comprehensive information about the Terraform infrastructure setup for the RedBus DevOps project.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [File Structure](#-file-structure)
- [Resources Created](#-resources-created)
- [Variables Reference](#-variables-reference)
- [Outputs Reference](#-outputs-reference)
- [Getting Started](#-getting-started)
- [Remote State Configuration](#-remote-state-configuration)
- [Customization](#-customization)
- [Common Operations](#-common-operations)
- [Troubleshooting](#-troubleshooting)
- [Cost Estimation](#-cost-estimation)

---

## 📌 Overview

The Terraform configuration provisions a complete AWS infrastructure for running the RedBus application on Amazon EKS. It uses official Terraform modules for AWS VPC and EKS to ensure best practices and maintainability.

### Infrastructure as Code (IaC)

| Aspect | Details |
|--------|---------|
| **Tool** | Terraform |
| **Version** | >= 1.0 |
| **Provider** | AWS (hashicorp/aws) |
| **Modules** | terraform-aws-modules/vpc, terraform-aws-modules/eks |
| **State Backend** | AWS S3 with DynamoDB locking |
| **Language** | HCL (HashiCorp Configuration Language) |

### AWS Cloud Services Used

| Service | Resource | Purpose |
|---------|----------|---------|
| **Amazon VPC** | redbus-vpc | Virtual Private Cloud for network isolation (CIDR: 10.0.0.0/16) |
| **Amazon EKS** | redbus-cluster | Managed Kubernetes cluster (v1.29) for container orchestration |
| **Amazon ECR** | redbus-frontend, redbus-backend | Container registry for Docker images with vulnerability scanning |
| **Amazon EC2** | t3.medium instances | Worker nodes for EKS managed node group (1-5 nodes) |
| **AWS IAM** | Roles & Policies | Identity and access management for EKS, EC2, ECR permissions |
| **Amazon S3** | terraform-state bucket | Remote state storage for Terraform with versioning enabled |
| **NAT Gateway** | Single NAT (dev) | Enables private subnet resources to access the internet |
| **Internet Gateway** | IGW | Provides internet connectivity to public subnets |
| **Elastic IP** | NAT Gateway EIP | Static public IP for NAT Gateway |

### AWS Services Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                   AWS CLOUD (us-east-1)                                  │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐                   │
│   │    AWS IAM      │     │    Amazon S3    │     │   Amazon ECR    │                   │
│   │  ─────────────  │     │  ─────────────  │     │  ─────────────  │                   │
│   │ • EKS Cluster   │     │ • TF State      │     │ • Frontend Repo │                   │
│   │   Role          │     │ • State Locking │     │ • Backend Repo  │                   │
│   │ • Node Group    │     │ • Versioning    │     │ • Image Scan    │                   │
│   │   Role          │     │                 │     │                 │                   │
│   └─────────────────┘     └─────────────────┘     └─────────────────┘                   │
│                                                                                          │
│   ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│   │                              AMAZON VPC (10.0.0.0/16)                            │  │
│   │  ┌────────────────────────────────────────────────────────────────────────────┐  │  │
│   │  │                     PUBLIC SUBNETS (Internet Gateway)                      │  │  │
│   │  │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌──────────────┐  │  │  │
│   │  │   │ 10.0.101/24 │   │ 10.0.102/24 │   │ 10.0.103/24 │   │ NAT Gateway  │  │  │  │
│   │  │   │   AZ-1a     │   │   AZ-1b     │   │   AZ-1c     │   │ + Elastic IP │  │  │  │
│   │  │   └─────────────┘   └─────────────┘   └─────────────┘   └──────┬───────┘  │  │  │
│   │  └────────────────────────────────────────────────────────────────┼──────────┘  │  │
│   │                                                                    │             │  │
│   │  ┌────────────────────────────────────────────────────────────────▼──────────┐  │  │
│   │  │                     PRIVATE SUBNETS (NAT Gateway)                         │  │  │
│   │  │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                     │  │  │
│   │  │   │ 10.0.1.0/24 │   │ 10.0.2.0/24 │   │ 10.0.3.0/24 │                     │  │  │
│   │  │   │   AZ-1a     │   │   AZ-1b     │   │   AZ-1c     │                     │  │  │
│   │  │   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                     │  │  │
│   │  │          │                 │                 │                             │  │  │
│   │  │   ┌──────▼─────────────────▼─────────────────▼──────┐                     │  │  │
│   │  │   │              AMAZON EKS (redbus-cluster)        │                     │  │  │
│   │  │   │  ┌────────────────────────────────────────────┐ │                     │  │  │
│   │  │   │  │     AMAZON EC2 - Managed Node Group        │ │                     │  │  │
│   │  │   │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐   │ │                     │  │  │
│   │  │   │  │  │t3.medium │ │t3.medium │ │t3.medium │   │ │                     │  │  │
│   │  │   │  │  │  Node 1  │ │  Node 2  │ │  Node n  │   │ │                     │  │  │
│   │  │   │  │  └──────────┘ └──────────┘ └──────────┘   │ │                     │  │  │
│   │  │   │  └────────────────────────────────────────────┘ │                     │  │  │
│   │  │   └─────────────────────────────────────────────────┘                     │  │  │
│   │  └───────────────────────────────────────────────────────────────────────────┘  │  │
│   └──────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud (us-east-1)                          │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         VPC (10.0.0.0/16)                             │  │
│  │                                                                       │  │
│  │   ┌─────────────────────────────────────────────────────────────┐    │  │
│  │   │                    Public Subnets                            │    │  │
│  │   │  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐      │    │  │
│  │   │  │ 10.0.101.0/24 │ │ 10.0.102.0/24 │ │ 10.0.103.0/24 │      │    │  │
│  │   │  │   us-east-1a  │ │   us-east-1b  │ │   us-east-1c  │      │    │  │
│  │   │  └───────────────┘ └───────────────┘ └───────────────┘      │    │  │
│  │   └─────────────────────────────┬───────────────────────────────┘    │  │
│  │                                 │                                     │  │
│  │                          ┌──────▼──────┐                              │  │
│  │                          │ NAT Gateway │                              │  │
│  │                          └──────┬──────┘                              │  │
│  │                                 │                                     │  │
│  │   ┌─────────────────────────────▼───────────────────────────────┐    │  │
│  │   │                    Private Subnets                           │    │  │
│  │   │  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐      │    │  │
│  │   │  │  10.0.1.0/24  │ │  10.0.2.0/24  │ │  10.0.3.0/24  │      │    │  │
│  │   │  │   us-east-1a  │ │   us-east-1b  │ │   us-east-1c  │      │    │  │
│  │   │  └───────┬───────┘ └───────┬───────┘ └───────┬───────┘      │    │  │
│  │   │          │                 │                 │               │    │  │
│  │   │   ┌──────▼─────────────────▼─────────────────▼──────┐       │    │  │
│  │   │   │              EKS Cluster (redbus-cluster)       │       │    │  │
│  │   │   │                  Kubernetes 1.29                │       │    │  │
│  │   │   │  ┌────────────────────────────────────────┐    │       │    │  │
│  │   │   │  │         Managed Node Group             │    │       │    │  │
│  │   │   │  │   t3.medium (min:1, max:5, desired:2)  │    │       │    │  │
│  │   │   │  └────────────────────────────────────────┘    │       │    │  │
│  │   │   └─────────────────────────────────────────────────┘       │    │  │
│  │   └─────────────────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                              ECR Repositories                        │   │
│  │  ┌─────────────────────────┐  ┌─────────────────────────┐           │   │
│  │  │    redbus-frontend      │  │     redbus-backend      │           │   │
│  │  │   (scan on push: ✓)     │  │    (scan on push: ✓)    │           │   │
│  │  └─────────────────────────┘  └─────────────────────────┘           │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

### Required Software

| Software | Version | Installation |
|----------|---------|--------------|
| Terraform | >= 1.0 | [Install Guide](#terraform-installation) |
| AWS CLI | 2.0+ | `aws configure` |
| kubectl | 1.28+ | For K8s management |

### AWS Requirements

- AWS Account with admin privileges
- IAM user with programmatic access
- Configured AWS CLI credentials

### Terraform Installation

```bash
# Amazon Linux / RHEL / CentOS
sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# macOS
brew install terraform

# Verify installation
terraform -v
```

---

## 📁 File Structure

```
infra/terraform/
├── provider.tf      # AWS & Kubernetes provider configuration
├── main.tf          # Main resources (VPC, EKS, ECR)
├── variables.tf     # Input variable definitions
├── outputs.tf       # Output value definitions
└── backend.tf       # Remote state configuration (S3)
```

### File Descriptions

| File | Purpose |
|------|---------|
| `provider.tf` | Configures AWS and Kubernetes providers with required versions |
| `main.tf` | Defines all AWS resources using modules and resources |
| `variables.tf` | Declares input variables with defaults and descriptions |
| `outputs.tf` | Exposes useful values after deployment |
| `backend.tf` | Configures S3 remote state for team collaboration |

---

## 🏗️ Resources Created

### Summary Table

| Resource Type | Name | Details |
|---------------|------|---------|
| VPC | redbus-vpc | CIDR: 10.0.0.0/16 |
| Public Subnets | 3 subnets | 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24 |
| Private Subnets | 3 subnets | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 |
| NAT Gateway | 1 (single in dev) | For private subnet internet access |
| EKS Cluster | redbus-cluster | Kubernetes 1.29 |
| Node Group | redbus-nodes | t3.medium, 1-5 nodes |
| ECR Repository | redbus-frontend | Image scanning enabled |
| ECR Repository | redbus-backend | Image scanning enabled |

### VPC Module

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr                    # 10.0.0.0/16

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment == "dev" ? true : false
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS integration
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
```

### EKS Cluster Module

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name          # redbus-cluster
  cluster_version = var.kubernetes_version    # 1.29

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    main = {
      name           = "redbus-nodes"
      instance_types = var.node_instance_types   # ["t3.medium"]
      min_size       = var.node_min_size         # 1
      max_size       = var.node_max_size         # 5
      desired_size   = var.node_desired_size     # 2
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_cluster_creator_admin_permissions = true
}
```

### ECR Repositories

```hcl
# Frontend Repository
resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Backend Repository
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle Policy - Keep last 10 images
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = toset([aws_ecr_repository.frontend.name, aws_ecr_repository.backend.name])
  repository = each.value

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
```

---

## 📊 Variables Reference

### General Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | `"redbus"` | Name of the project |
| `environment` | string | `"dev"` | Environment name (dev/staging/prod) |
| `aws_region` | string | `"us-east-1"` | AWS region for deployment |

### VPC Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_cidr` | string | `"10.0.0.0/16"` | CIDR block for VPC |
| `availability_zones` | list(string) | `["us-east-1a", "us-east-1b", "us-east-1c"]` | Availability zones |
| `private_subnets` | list(string) | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | Private subnet CIDRs |
| `public_subnets` | list(string) | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | Public subnet CIDRs |

### EKS Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | `"redbus-cluster"` | Name of the EKS cluster |
| `kubernetes_version` | string | `"1.29"` | Kubernetes version |
| `node_instance_types` | list(string) | `["t3.medium"]` | Instance types for nodes |
| `node_min_size` | number | `1` | Minimum number of nodes |
| `node_max_size` | number | `5` | Maximum number of nodes |
| `node_desired_size` | number | `2` | Desired number of nodes |

### Customizing Variables

Create a `terraform.tfvars` file:

```hcl
# terraform.tfvars
project_name     = "redbus"
environment      = "prod"
aws_region       = "us-east-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# EKS Configuration
cluster_name       = "redbus-cluster"
kubernetes_version = "1.29"
node_instance_types = ["t3.large"]
node_min_size      = 2
node_max_size      = 10
node_desired_size  = 3
```

---

## 📤 Outputs Reference

After successful deployment, these values are available:

### VPC Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | The ID of the created VPC |
| `private_subnets` | List of private subnet IDs |
| `public_subnets` | List of public subnet IDs |

### EKS Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS cluster API endpoint |
| `cluster_security_group_id` | Security group ID for the cluster |
| `cluster_iam_role_arn` | IAM role ARN of the EKS cluster |

### ECR Outputs

| Output | Description |
|--------|-------------|
| `ecr_frontend_url` | ECR repository URL for frontend images |
| `ecr_backend_url` | ECR repository URL for backend images |

### Utility Outputs

| Output | Description |
|--------|-------------|
| `configure_kubectl` | Command to configure kubectl for the cluster |

---

## 🚀 Getting Started

### Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Verify access
aws sts get-caller-identity
```

### Step 2: Initialize Terraform

```bash
cd infra/terraform

# Initialize Terraform (downloads providers & modules)
terraform init
```

### Step 3: Review the Plan

```bash
# See what will be created
terraform plan

# Save plan to file
terraform plan -out=tfplan
```

### Step 4: Apply Infrastructure

```bash
# Apply the configuration
terraform apply

# Or apply saved plan
terraform apply tfplan

# Auto-approve (use with caution)
terraform apply -auto-approve
```

### Step 5: Configure kubectl

```bash
# Get the configure command from outputs
terraform output configure_kubectl

# Run the command
aws eks update-kubeconfig --region us-east-1 --name redbus-cluster

# Verify connection
kubectl get nodes
```

---

## 💾 Remote State Configuration

The project uses S3 backend for remote state storage with state locking.

### Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket       = "redbus-terraform-state"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### Setup Remote State Backend

Before using the remote backend, create the required AWS resources:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket redbus-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket redbus-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket redbus-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket redbus-terraform-state \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'
```

### State Locking

Terraform 1.10+ uses native S3 locking (`use_lockfile = true`). For older versions, create a DynamoDB table:

```bash
aws dynamodb create-table \
  --table-name redbus-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## ⚙️ Customization

### Multi-Environment Setup

Create separate variable files for each environment:

```bash
infra/terraform/
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
```

**dev.tfvars:**
```hcl
environment         = "dev"
node_instance_types = ["t3.medium"]
node_min_size       = 1
node_max_size       = 3
node_desired_size   = 1
```

**prod.tfvars:**
```hcl
environment         = "prod"
node_instance_types = ["t3.large", "t3.xlarge"]
node_min_size       = 3
node_max_size       = 10
node_desired_size   = 5
```

Apply with environment file:
```bash
terraform apply -var-file=environments/prod.tfvars
```

### Adding New Resources

Example: Adding an RDS database

```hcl
# Add to main.tf
resource "aws_db_instance" "redbus_db" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "redbus"
  username             = "admin"
  password             = var.db_password
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
}
```

---

## 🔧 Common Operations

### View Current State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show module.eks.aws_eks_cluster.this[0]
```

### Update Infrastructure

```bash
# Update after changing variables
terraform plan
terraform apply
```

### Scale Node Group

Update `variables.tf` or `terraform.tfvars`:

```hcl
node_min_size     = 2
node_max_size     = 10
node_desired_size = 5
```

Then apply:
```bash
terraform apply
```

### Destroy Infrastructure

```bash
# Preview destruction
terraform plan -destroy

# Destroy all resources (CAUTION!)
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_ecr_repository.frontend
```

### Import Existing Resources

```bash
# Import existing ECR repository
terraform import aws_ecr_repository.frontend redbus-frontend
```

### Refresh State

```bash
# Sync state with actual infrastructure
terraform refresh
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. State Lock Error

```bash
# Error: Error acquiring the state lock

# Solution: Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### 2. Provider Authentication Error

```bash
# Error: error configuring Terraform AWS Provider

# Solution: Verify AWS credentials
aws sts get-caller-identity
aws configure list
```

#### 3. Module Download Failure

```bash
# Error: Failed to download module

# Solution: Clear cache and reinitialize
rm -rf .terraform
terraform init -upgrade
```

#### 4. EKS Cluster Access Denied

```bash
# Error: Unauthorized when connecting to EKS

# Solution: Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name redbus-cluster

# Verify IAM identity
aws sts get-caller-identity
```

#### 5. Subnet Capacity Issues

```bash
# Error: Not enough IP addresses in subnet

# Solution: Use larger CIDR blocks or fewer AZs
# Update variables.tf with larger subnets
```

#### 6. NAT Gateway Limit

```bash
# Error: NAT Gateway limit exceeded

# Solution: Request limit increase or use single NAT Gateway
single_nat_gateway = true  # For dev environment
```

---

## 💰 Cost Estimation

### Monthly Cost Breakdown (Approximate)

| Resource | Specification | Est. Monthly Cost |
|----------|---------------|-------------------|
| EKS Cluster | Control plane | $73 |
| EC2 Nodes | 2x t3.medium | $60 |
| NAT Gateway | 1x (single) | $32 + data |
| ECR Storage | ~5 GB | $0.50 |
| Data Transfer | Variable | Variable |
| **Total (Dev)** | | **~$170/month** |

### Cost Optimization Tips

1. **Use Spot Instances** for non-production:
   ```hcl
   capacity_type = "SPOT"
   ```

2. **Single NAT Gateway** for dev environments:
   ```hcl
   single_nat_gateway = true
   ```

3. **Right-size nodes** based on actual usage

4. **ECR Lifecycle Policy** to clean old images (already configured)

5. **Consider Reserved Instances** for production

---

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS EKS Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

<p align="center">
  <b>🔧 Infrastructure as Code by RedBus DevOps Team</b>
</p>
