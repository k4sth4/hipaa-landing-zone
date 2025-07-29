variable "lambda_function_name" {
  description = "Name of the Lambda function that evaluates EBS encryption"
  type        = string
}

variable "config_rule_name" {
  description = "Name of the AWS Config rule to check EBS encryption"
  type        = string
}
