terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_iam_group" "admins" {
  provider = aws
  name     = "Admins"
}

resource "aws_iam_group_policy_attachment" "admin_attach" {
  provider   = aws
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}