output "lambda_function_arn" {
  value       = aws_lambda_function.ebs_encryption_checker.arn
  description = "The ARN of the EBS encryption checker Lambda function"
}

output "config_rule_name" {
  value       = aws_config_config_rule.ebs_encryption_check.name
  description = "Name of the AWS Config custom rule for EBS encryption check"
}
