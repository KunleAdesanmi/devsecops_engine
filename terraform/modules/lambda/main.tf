resource "aws_iam_role" "lambda_exec" {
  name = "ch_lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

# Grants Lambda permission to see S3 Buckets (for your scanner)
resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_function" "scanner" {
  function_name = "ch-security-scanner"
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repo_url}:latest"
  timeout       = 30
}