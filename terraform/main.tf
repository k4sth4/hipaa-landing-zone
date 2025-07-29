module "iam_security" {
  source        = "./modules/iam-bootstrap"
  account_alias = "security-account"
  providers = {
    aws = aws.security
  }
}

module "iam_dev" {
  source        = "./modules/iam-bootstrap"
  account_alias = "dev-account"
  providers = {
    aws = aws.dev
  }
}

module "iam_prod" {
  source        = "./modules/iam-bootstrap"
  account_alias = "prod-account"
  providers = {
    aws = aws.prod
  }
}

module "iam_shared" {
  source        = "./modules/iam-bootstrap"
  account_alias = "shared-account"
  providers = {
    aws = aws.shared
  }
}
