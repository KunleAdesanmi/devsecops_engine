# Learning Notes - DevSecOps Engine Project

## Today's Session Summary

### Overview
Today we worked on deploying a DevSecOps security scanner using AWS Lambda, Terraform, Docker, and GitHub Actions. The project scans S3 buckets for public access vulnerabilities.

---

## Key Learning Points

### 1. Terraform Working Directory Requirements

**Problem Encountered:**
```
Error: No configuration files
Apply requires configuration to be present.
```

**Root Cause:**
- Terraform looks for `.tf` files in the **current working directory**
- Running `terraform apply` from the project root (`devsecops_engine/`) instead of the terraform directory (`devsecops_engine/terraform/`)

**Solution:**
```bash
# Always change to the terraform directory first
cd devsecops_engine/terraform
terraform apply

# OR use the -chdir flag (Terraform 0.14+)
terraform -chdir=devsecops_engine/terraform apply
```

**Key Learning:**
- Terraform resolves relative paths (like `./modules/vpc`) relative to where you run the command
- The `.terraform` directory (created by `terraform init`) is created in the current working directory
- **Best Practice:** Always run Terraform commands from the directory containing your `.tf` files

---

### 2. Terraform Initialization Process

**Problem Encountered:**
```
Error: Module not installed
This module is not yet installed. Run "terraform init" to install all modules required by this configuration.
```

**Root Cause:**
- Terraform must be initialized before any other operations (`validate`, `plan`, `apply`)
- Initialization downloads providers, sets up backend, and prepares modules

**What `terraform init` Does:**
1. **Downloads Providers:** Fetches required providers (e.g., AWS provider ~> 5.0)
2. **Initializes Backend:** Sets up remote state storage (S3 in this case)
3. **Prepares Modules:** Installs local and remote modules

**Terraform Workflow Order:**
```bash
1. terraform init      # First time, or after adding providers/modules
2. terraform validate  # Check syntax and configuration
3. terraform plan      # Preview changes
4. terraform apply     # Apply changes
```

**Key Learning:**
- Always run `terraform init` first
- Re-run `terraform init` after:
  - Adding new providers
  - Adding new modules
  - Changing backend configuration
  - Cloning a repository

---

### 3. ECR Repository URL Format

**Problem Encountered:**
```
Error: InvalidParameterValueException: Source image https://{account-id}.signin.aws.amazon.com/console:latest is not valid.
```

**Root Cause:**
- Entered AWS Console sign-in URL instead of ECR repository URL
- ECR URLs have a specific format

**Correct ECR URL Format:**
```
{account-id}.dkr.ecr.{region}.amazonaws.com/{repository-name}
```

**Examples:**
- ✅ Correct: `{account-id}.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine`
- ❌ Wrong: `https://{account-id}.signin.aws.amazon.com/console` (AWS Console URL)
- ❌ Wrong: `{account-id}.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine/security-engine` (extra slash)

**Key Learning:**
- ECR repository URLs do NOT include:
  - `https://` protocol prefix
  - Extra path segments (only one repository name)
  - AWS Console URLs
- Format: `{account-id}.dkr.ecr.{region}.amazonaws.com/{repo-name}`

**How to Find Your ECR URL:**
1. AWS Console → ECR → Repositories → Click repository → Copy "URI"
2. Or use AWS CLI: `aws ecr describe-repositories --query 'repositories[*].repositoryUri'`

---

### 4. Docker Image Tagging with Environment Variables

**Problem Encountered:**
```
Error parsing reference: ".dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:latest" is not a valid repository/tag
```

**Root Cause:**
- Environment variable `$AWS_ID` was not set
- When unset, bash expands it to empty string, resulting in invalid tag starting with `.`

**Solution:**
```bash
# Option 1: Set environment variable
export AWS_ID={account-id}
docker tag devsecops-engine:latest $AWS_ID.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:latest

# Option 2: Use account ID directly
docker tag devsecops-engine:latest {account-id}.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:latest

# Option 3: Get account ID dynamically
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag devsecops-engine:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:latest
```

**Key Learning:**
- Always verify environment variables are set before using them
- Use `echo $VARIABLE_NAME` to check if variable is set
- Consider using AWS CLI to get account ID dynamically: `aws sts get-caller-identity --query Account --output text`

---

### 5. Lambda Function Image URI Configuration

**Problem Encountered:**
```
Error: InvalidParameterValueException: Source image .../devsecops-engine/security-engine:v2:latest is not valid.
```

**Root Cause:**
- Lambda module was appending `:latest` automatically: `"${var.ecr_repo_url}:latest"`
- User provided URL already included tag `:v2`
- Result: `:v2:latest` (invalid - duplicate tags)

**Original Code:**
```hcl
image_uri = "${var.ecr_repo_url}:latest"  # Always appends :latest
```

**Solution Applied:**
```hcl
image_uri = "${var.ecr_repo_url}:v2"  # Hardcoded tag (current approach)
```

**Alternative Solutions:**
1. **Provide full URI with tag:** Pass complete ECR URI including tag, remove `:latest` append
2. **Use separate variable:** Create `image_tag` variable for flexibility
3. **Use data source:** Query ECR for latest image digest

**Key Learning:**
- Lambda container images require complete ECR URI: `{registry}/{repo}:{tag}`
- Avoid double-tagging (e.g., `:v2:latest`)
- Consider making tags configurable for better CI/CD integration
- ECR image URIs can use tags (`:v2`) or digests (`@sha256:...`)

---

### 6. Terraform Module Structure

**Project Structure:**
```
devsecops_engine/
├── terraform/
│   ├── main.tf              # Root module - orchestrates everything
│   ├── variable.tf          # Root variables
│   ├── output.tf            # Root outputs
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf      # VPC resources
│       │   └── variable.tf  # VPC module variables
│       └── lambda/
│           ├── main.tf      # Lambda resources
│           └── variable.tf  # Lambda module variables
```

**Module Usage:**
```hcl
# In root main.tf
module "network" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}

module "security_scanner" {
  source       = "./modules/lambda"
  ecr_repo_url = var.ecr_repo_url
}
```

**Key Learning:**
- Modules promote code reusability and organization
- Local modules use `./modules/name` syntax
- Variables passed to modules must be declared in module's `variable.tf`
- Root module variables are separate from module variables

---

### 7. Terraform Backend Configuration

**Backend Setup:**
```hcl
terraform {
  backend "s3" {
    bucket = "devsecops-engine-tf-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Key Learning:**
- Remote state storage prevents state file conflicts in team environments
- S3 backend requires:
  - S3 bucket to exist (create manually or with separate Terraform)
  - Proper IAM permissions
  - Versioning enabled (recommended)
  - State locking (DynamoDB table, optional but recommended)

---

### 8. GitHub Actions CI/CD Pipeline

**Pipeline Steps:**
1. **Checkout:** Get code from repository
2. **Configure AWS:** Authenticate using secrets
3. **ECR Login:** Authenticate Docker to ECR
4. **Build & Push:** Build Docker image and push to ECR
5. **Terraform Deploy:** Initialize and apply infrastructure

**Key Learning:**
- GitHub Actions uses `${{ secrets.NAME }}` for sensitive data
- ECR login action outputs registry URL: `${{ steps.login-ecr.outputs.registry }}`
- Always run Terraform from correct directory (`cd terraform`)
- Use `-auto-approve` flag for CI/CD (non-interactive)

---

## Common Errors & Solutions Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `No configuration files` | Wrong directory | `cd terraform` first |
| `Module not installed` | Not initialized | Run `terraform init` |
| `Invalid ECR URL` | Wrong format | Use `{account}.dkr.ecr.{region}.amazonaws.com/{repo}` |
| `Invalid repository/tag` | Unset env var | Set variable or use value directly |
| `Duplicate tags` | Module appends tag | Remove auto-append or provide full URI |

---

## Best Practices Learned

1. **Always run Terraform from the terraform directory**
2. **Initialize Terraform before any operation**
3. **Use correct ECR URL format** (no https://, no extra slashes)
4. **Verify environment variables before use**
5. **Avoid hardcoding tags** - use variables or CI/CD outputs
6. **Test locally before pushing to CI/CD**
7. **Use versioned tags** (`:v2`) instead of `:latest` for immutability
8. **Store Terraform state remotely** for team collaboration

---

## Next Steps for Improvement

1. **Make image tag configurable** via Terraform variable
2. **Add Terraform state locking** (DynamoDB table)
3. **Use ECR image digests** instead of tags for true immutability
4. **Add Terraform validation** to CI/CD pipeline
5. **Create separate environments** (dev/staging/prod) using workspaces
6. **Add error handling** and rollback strategies
7. **Document all required AWS resources** (S3 bucket for state, ECR repo, etc.)

---

## Useful Commands Reference

```bash
# Terraform
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -var="ecr_repo_url=..."

# Docker & ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com
docker build -t devsecops-engine:v2 ./app
docker tag devsecops-engine:v2 {account-id}.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:v2
docker push {account-id}.dkr.ecr.us-east-1.amazonaws.com/devsecops-engine:v2

# AWS CLI
aws sts get-caller-identity --query Account --output text
aws ecr describe-repositories --query 'repositories[*].repositoryUri'
```

---

## Date: January 18, 2026
## Project: DevSecOps Engine - AWS Lambda Security Scanner
