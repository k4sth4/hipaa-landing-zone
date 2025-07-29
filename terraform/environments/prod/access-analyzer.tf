module "access_analyzer_prod" {
  source = "../../modules/access-analyzer"

  providers = {
    aws = aws.prod
  }

  analyzer_name = "AccessAnalyzer-Prod"
  analyzer_type = "ACCOUNT"
  tags = {
    Environment = "prod"
    Project     = "HIPAA-Landing-Zone"
  }
}