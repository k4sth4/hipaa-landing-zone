module "dev_app_role" {
  source = "../../modules/iam"

  providers = {
    aws = aws.dev
  }

  role_name          = "DevAppRole"
  policy_path        = "../../policies/dev_app_policy.json"
  trusted_entity_arn = "arn:aws:iam::088044431771:root"

  tags = {
    Environment = "dev"
    Project     = "HIPAA-Landing-Zone"
  }
}

module "audit_role_dev" {
  source = "../../modules/iam"

  providers = {
    aws = aws.dev
  }

  role_name          = "AuditRole-Dev"
  policy_path        = "../../policies/audit_policy.json"
  trusted_entity_arn = "arn:aws:iam::292725948066:root"

  tags = {
    Environment = "dev"
    Project     = "HIPAA-Landing-Zone"
  }
}