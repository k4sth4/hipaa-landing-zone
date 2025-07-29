resource "aws_iam_role" "lambda_exec" {
  name = "EBSConfigLambdaExecRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "config_permissions" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole"
}

resource "aws_lambda_function" "ebs_encryption_checker" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
  handler       = "ebs_encryption_checker.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 60
}

resource "aws_lambda_permission" "allow_config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_encryption_checker.arn
  principal     = "config.amazonaws.com"
  source_account = "292725948066"

  depends_on = [aws_lambda_function.ebs_encryption_checker]
}

resource "aws_config_config_rule" "ebs_encryption_check" {
  name = var.config_rule_name

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.ebs_encryption_checker.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Volume"]
  }

  input_parameters            = jsonencode({})
  maximum_execution_frequency = "TwentyFour_Hours"

  depends_on = [aws_lambda_permission.allow_config]
}
