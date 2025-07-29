module "prod_ops_role" {
  source             = "../../modules/iam"
  role_name          = "ProdOpsRole"
  policy_path        = "../../policies/prod_ops_policy.json"
  trusted_entity_arn = "arn:aws:iam::674845782471:root" # Prod account

  tags = {
    Environment = "prod"
    Project     = "HIPAA-Landing-Zone"
  }
}

module "audit_role_prod" {
  source             = "../../modules/iam"
  role_name          = "AuditRole"
  policy_path        = "../../policies/audit_policy.json"
  trusted_entity_arn = "arn:aws:iam::292725948066:root" # Security account

  tags = {
    Environment = "prod"
    Project     = "HIPAA-Landing-Zone"
  }
}