# 🔒 DevSecOps Engine

> **Automated S3 Security Scanner for AWS**

A cloud-native security auditing tool that automatically identifies S3 buckets lacking "Public Access Block" configurations, helping prevent data leaks and maintain compliance.

[![Terraform](https://img.shields.io/badge/Terraform-0.14+-blue)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Lambda-orange)](https://aws.amazon.com/lambda/)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue)](https://www.docker.com/)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Manual Deployment](#manual-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Usage](#usage)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Learning Resources](#learning-resources)

---

## 🎯 Overview

The DevSecOps Engine is an automated security scanner that:

- **Scans** all S3 buckets in your AWS account
- **Identifies** buckets without Public Access Block enabled
- **Reports** security findings via CloudWatch Logs
- **Runs** as a serverless Lambda function (zero infrastructure management)
- **Deploys** automatically via GitHub Actions CI/CD

---

## ✨ Features

- 🔍 **Automated Scanning**: Continuously monitors S3 bucket security configurations
- 🚀 **Serverless**: Runs on AWS Lambda - pay only for execution time
- 🐳 **Containerized**: Docker-based Lambda for consistent runtime environment
- 🏗️ **Infrastructure as Code**: Fully managed with Terraform
- 🔄 **CI/CD Ready**: Automated deployment via GitHub Actions
- 🛡️ **Secure by Default**: Least-privilege IAM roles and VPC isolation
- 📊 **CloudWatch Integration**: All logs and metrics in one place

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| **Application** | Python 3.11 with boto3 (AWS SDK) |
| **Packaging** | Docker (Containerized Lambda Runtime) |
| **Infrastructure** | Terraform (Modular IaC) |
| **CI/CD** | GitHub Actions |
| **Container Registry** | AWS Elastic Container Registry (ECR) |
| **Monitoring** | AWS CloudWatch Logs |
| **Networking** | Custom VPC with private subnet |

### Architecture Diagram

```
┌─────────────────┐
│  GitHub Actions │
│   (CI/CD)       │
└────────┬────────┘
         │
         ├──► Build Docker Image
         │
         ├──► Push to ECR
         │
         └──► Terraform Apply
                  │
                  ▼
         ┌─────────────────┐
         │  AWS Lambda     │
         │  (Scanner)      │
         └────────┬────────┘
                  │
                  ├──► Scan S3 Buckets
                  │
                  └──► CloudWatch Logs
```

### The Pipeline

The project follows a modern GitOps workflow:

1. **Code Push** → Developers push code to the `main` branch
2. **CI Trigger** → GitHub Actions authenticates to AWS via IAM secrets
3. **Image Build** → Docker image is built from `./app` directory
4. **ECR Push** → Image is tagged and pushed to ECR with versioned tags (v1, v2, etc.)
5. **Terraform Apply** → Infrastructure is updated, Lambda function points to new image
6. **Zero Downtime** → Lambda updates seamlessly without service interruption

---

## 📦 Prerequisites

Before you begin, ensure you have:

- **AWS Account** with appropriate permissions
- **AWS CLI** installed and configured (`aws configure`)
- **Terraform** >= 0.14 installed ([Download](https://www.terraform.io/downloads))
- **Docker** installed and running ([Download](https://www.docker.com/get-started))
- **Git** for version control
- **Python 3.11** (for local development/testing)

### AWS Resources Required

You'll need to create these resources manually (or via separate Terraform):

1. **S3 Bucket** for Terraform state: `devsecops-engine-tf-state`
   - Enable versioning
   - Recommended: Enable encryption
   - Region: `us-east-1` (or update backend config)

2. **ECR Repository**: `devsecops-engine`
   - Region: `us-east-1` (or update provider config)
   - Create via AWS Console or CLI:
     ```bash
     aws ecr create-repository --repository-name devsecops-engine --region us-east-1
     ```

3. **GitHub Secrets** (for CI/CD):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

---

## 📁 Project Structure

```
devsecops_engine/
├── app/
│   ├── Dockerfile          # Lambda container image definition
│   └── scanner.py          # Main Lambda function code
├── terraform/
│   ├── main.tf             # Root module - orchestrates resources
│   ├── variable.tf         # Root variables
│   ├── output.tf           # Root outputs
│   └── modules/
│       ├── vpc/            # VPC and networking module
│       │   ├── main.tf
│       │   └── variable.tf
│       └── lambda/         # Lambda function module
│           ├── main.tf
│           └── variable.tf
├── .github/
│   └── workflows/
│       └── main.yml        # CI/CD pipeline definition
├── README.md               # This file
└── LEARNING_NOTES.md       # Detailed learning notes and troubleshooting
```

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

1. **Fork/Clone** this repository
2. **Configure GitHub Secrets**:
   - Go to Settings → Secrets → Actions
   - Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
3. **Push to main branch** → GitHub Actions will automatically deploy

### Option 2: Manual Deployment

See [Manual Deployment](#manual-deployment) section below.

---

## 🛠️ Manual Deployment

### Step 1: Build and Push Docker Image

```bash
# Navigate to project root
cd devsecops_engine

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build the image
docker build -t devsecops-engine:v2 ./app

# Tag for ECR
docker tag devsecops-engine:v2 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:v2

# Push to ECR
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:v2
```

**Replace `<ACCOUNT_ID>` with your AWS account ID.**

Get your account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

### Step 2: Deploy Infrastructure with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (downloads providers, sets up backend)
terraform init

# Review the execution plan
terraform plan -var="ecr_repo_url=<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine"

# Apply the configuration
terraform apply -var="ecr_repo_url=<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine"
```

**Important:** Always run Terraform commands from the `terraform/` directory!

### Step 3: Verify Deployment

```bash
# Check Lambda function
aws lambda get-function --function-name ch-security-scanner

# View CloudWatch Logs
aws logs tail /aws/lambda/ch-security-scanner --follow
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/main.yml`) automates:

1. **Checkout** code from repository
2. **Configure AWS** credentials using GitHub secrets
3. **Login to ECR** and get registry URL
4. **Build & Push** Docker image to ECR
5. **Setup Terraform** and initialize
6. **Deploy** infrastructure with `terraform apply`

### Pipeline Configuration

The pipeline uses:
- **ECR Repository**: `devsecops-engine`
- **Image Tag**: `v2` (configurable in workflow file)
- **AWS Region**: `us-east-1`
- **Terraform Backend**: S3 bucket `devsecops-engine-tf-state`

### Customizing the Pipeline

To change the image tag or repository name, edit `.github/workflows/main.yml`:

```yaml
env:
  ECR_REPOSITORY: devsecops-engine  # Change repository name
  IMAGE_TAG: v2                     # Change tag (or use ${{ github.sha }})
```

---

## 📖 Usage

### Invoking the Lambda Function

The scanner runs automatically, but you can also invoke it manually:

```bash
# Invoke via AWS CLI
aws lambda invoke \
  --function-name ch-security-scanner \
  --payload '{}' \
  response.json

# View response
cat response.json
```

### Viewing Results

Results are logged to CloudWatch Logs:

```bash
# Stream logs in real-time
aws logs tail /aws/lambda/ch-security-scanner --follow

# Get recent log events
aws logs get-log-events \
  --log-group-name /aws/lambda/ch-security-scanner \
  --log-stream-name <stream-name>
```

### Expected Output

The Lambda function returns a JSON array:

```json
[
  {
    "bucket": "my-secure-bucket",
    "fully_private": true
  },
  {
    "bucket": "public-bucket",
    "fully_private": false
  }
]
```

---

## 🛡️ Security Best Practices

This project implements several security best practices:

### 1. Least Privilege IAM Roles
- Lambda execution role has **only** the permissions needed:
  - `s3:GetBucketPublicAccessBlock`
  - `s3:ListAllMyBuckets`
  - CloudWatch Logs write permissions

### 2. Immutable Infrastructure
- **Versioned Docker tags** (`v1`, `v2`) instead of `:latest`
- Enables easy rollback if issues occur
- Prevents unexpected updates

### 3. Remote State Management
- Terraform state stored in **S3** with versioning
- Prevents state file conflicts in team environments
- Enables state locking (recommended: add DynamoDB table)

### 4. Infrastructure Isolation
- Resources deployed in **custom VPC**
- Private subnet for Lambda (if VPC configuration is added)
- Network-level security controls

### 5. Secrets Management
- AWS credentials stored as **GitHub Secrets**
- Never committed to repository
- Rotated regularly

---

## 🔧 Troubleshooting

### Common Issues

#### Error: "No configuration files"
**Cause:** Running Terraform from wrong directory  
**Solution:** Always run from `terraform/` directory:
```bash
cd terraform
terraform apply
```

#### Error: "Module not installed"
**Cause:** Terraform not initialized  
**Solution:** Run `terraform init` first

#### Error: "Invalid ECR URL"
**Cause:** Wrong ECR repository URL format  
**Solution:** Use format: `{account-id}.dkr.ecr.{region}.amazonaws.com/{repo-name}`  
**Note:** No `https://`, no extra slashes

#### Error: "Source image ... is not valid"
**Cause:** Image doesn't exist in ECR or wrong tag  
**Solution:** 
- Verify image exists: `aws ecr describe-images --repository-name devsecops-engine`
- Ensure tag matches what's in Terraform

#### Lambda Function Not Working
**Check:**
1. CloudWatch Logs for errors
2. IAM role permissions
3. Image URI is correct
4. VPC configuration (if applicable)

### Getting Help

For detailed troubleshooting and learning notes, see [LEARNING_NOTES.md](./LEARNING_NOTES.md).

---

## 📚 Learning Resources

- **[LEARNING_NOTES.md](./LEARNING_NOTES.md)** - Comprehensive learning notes covering:
  - Common errors and solutions
  - Terraform best practices
  - Docker and ECR workflows
  - AWS Lambda configuration
  - CI/CD pipeline details

### Useful Commands

```bash
# Terraform
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -var="ecr_repo_url=..."

# Docker & ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker build -t devsecops-engine:v2 ./app
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:v2

# AWS CLI
aws sts get-caller-identity --query Account --output text
aws ecr describe-repositories --query 'repositories[*].repositoryUri'
aws lambda get-function --function-name ch-security-scanner
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- AWS Lambda for serverless compute
- Terraform for infrastructure as code
- GitHub Actions for CI/CD automation

---

**Made with ❤️ for DevSecOps**

For questions or issues, please open an issue on GitHub.
