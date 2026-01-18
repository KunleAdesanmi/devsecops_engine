# devsecops_engine

AWS DevSecOps: Automated S3 Security Scanner
This project implements a fully automated, cloud-native security auditing tool. It identifies S3 buckets that lack "Public Access Block" configurations, helping to prevent data leaks.

🛠 Architecture & Tech Stack
Application: Python 3.11 with boto3 (AWS SDK).

Packaging: Docker (Containerized Lambda Runtime).

Infrastructure: Terraform (Modular IaC).

CI/CD: GitHub Actions (Automated build and deploy).

Cloud Registry: AWS Elastic Container Registry (ECR).

Monitoring: AWS CloudWatch Logs.

🚀 The Pipeline
The project follows a modern GitOps workflow:

Code Push: Developers push code to the main branch.

Continuous Integration: GitHub Actions authenticates to AWS via IAM Secrets.

Image Build: A new Docker image is built using a --no-cache policy to ensure integrity.

Registry Update: The image is pushed to AWS ECR with versioned tags (v1, v2).

Continuous Deployment: Terraform performs an apply, updating the Lambda function to point to the new image digest with zero downtime.

🛡 Security Best Practices Implemented
Least Privilege: IAM roles are scoped specifically to s3:GetBucketPublicAccessBlock and s3:ListAllMyBuckets.

Immutable Infrastructure: Versioned Docker tags are used instead of :latest to ensure rollback capabilities.

Remote State: Terraform state is stored in an S3 bucket with versioning and locking enabled to prevent state corruption in team environments.

Infrastructure Isolation: Resources are deployed within a custom VPC to ensure network control.

How to Run
Build and Push:

docker build -t security-engine:v2 ./app
docker tag security-engine:v2 <ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/security-engine:v2
docker push <ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/security-engine:v2

Deploy:

cd terraform
terraform init
terraform apply -var="ecr_repo_url=<ACCOUNT_ID>.dkr.ecr.eu-west-2.amazonaws.com/security-engine"