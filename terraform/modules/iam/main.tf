resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = var.trusted_entity_arn
        },
        Action = "sts:AssumeRole",
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this" {
  name   = "${var.role_name}-policy"
  policy = file(var.policy_path)
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}