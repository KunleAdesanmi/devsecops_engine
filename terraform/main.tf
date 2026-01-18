terraform {
  backend "s3" {
    bucket = "devsecops-engine-tf-state" 
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "us-east-1" }

module "network" {
  source      = "./modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}

module "security_scanner" {
  source       = "./modules/lambda"
  ecr_repo_url = var.ecr_repo_url
}