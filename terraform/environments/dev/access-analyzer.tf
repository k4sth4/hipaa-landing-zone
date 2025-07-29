module "access_analyzer_dev" {
  source = "../../modules/access-analyzer"

  providers = {
    aws = aws.dev
  }

  analyzer_name = "AccessAnalyzer-Dev"
  analyzer_type = "ACCOUNT"
  tags = {
    Environment = "dev"
    Project     = "HIPAA-Landing-Zone"
  }
}