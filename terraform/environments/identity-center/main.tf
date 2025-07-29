data "aws_ssoadmin_instances" "main" {}

resource "aws_identitystore_user" "devuser" {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  user_name    = "devuser"
  display_name = "Dev User"

  name {
    given_name  = "Dev"
    family_name = "User"
  }

  emails {
    value   = "devuser@hipaa-project.aws"
    primary = true
  }
}

resource "aws_identitystore_user" "produser" {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  user_name    = "produser"
  display_name = "Prod User"

  name {
    given_name  = "Prod"
    family_name = "User"
  }

  emails {
    value   = "produser@hipaa-project.aws"
    primary = true
  }
}

resource "aws_ssoadmin_permission_set" "devapp" {
  name         = "DevAppAccess"
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  description  = "Access to DevAppRole in Dev account"
  session_duration = "PT8H"

  tags = {
    Project = "HIPAA-Landing-Zone"
  }
}

resource "aws_ssoadmin_permission_set" "prodops" {
  name         = "ProdOpsAccess"
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  description  = "Access to ProdOpsRole in Prod account"
  session_duration = "PT8H"

  tags = {
    Project = "HIPAA-Landing-Zone"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "devapp_policy" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.devapp.arn

  inline_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "arn:aws:iam::088044431771:role/DevAppRole"
      }
    ]
  })
}

resource "aws_ssoadmin_permission_set_inline_policy" "prodops_policy" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.prodops.arn

  inline_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "arn:aws:iam::674845782471:role/ProdOpsRole"
      }
    ]
  })
}

resource "aws_ssoadmin_account_assignment" "devuser_devapp" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  principal_id       = aws_identitystore_user.devuser.user_id
  principal_type     = "USER"
  permission_set_arn = aws_ssoadmin_permission_set.devapp.arn
  target_id          = "088044431771" # Dev Account
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "produser_ops" {
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  principal_id       = aws_identitystore_user.produser.user_id
  principal_type     = "USER"
  permission_set_arn = aws_ssoadmin_permission_set.prodops.arn
  target_id          = "674845782471" # Prod Account
  target_type        = "AWS_ACCOUNT"
}