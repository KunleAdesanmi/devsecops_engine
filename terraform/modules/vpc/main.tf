resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "ch-project-vpc" }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
  tags       = { Name = "ch-private-subnet" }
}

output "vpc_id" { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.private.id }