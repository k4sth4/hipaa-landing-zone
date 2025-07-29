provider "aws" {
  alias   = "shared"
  profile = "shared"
  region  = "us-east-1"
}

module "access_analyzer_shared" {
  source = "../../modules/access-analyzer"

  providers = {
    aws = aws.shared
  }

  analyzer_name = "AccessAnalyzer-Shared"
  analyzer_type = "ACCOUNT"
  tags = {
    Environment = "shared"
    Project     = "HIPAA-Landing-Zone"
  }
}