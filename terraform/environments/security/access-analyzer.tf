provider "aws" {
  alias   = "security"
  profile = "security"
  region  = "us-east-1"
}

module "access_analyzer_org" {
  source = "../../modules/access-analyzer"

  providers = {
    aws = aws.security
  }

  analyzer_name = "AccessAnalyzer-Org"
  analyzer_type = "ORGANIZATION"
  tags = {
    Environment = "security"
    Scope       = "org-wide"
    Project     = "HIPAA-Landing-Zone"
  }
}