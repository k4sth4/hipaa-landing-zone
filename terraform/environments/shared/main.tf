provider "aws" {
  profile = "shared"
  region  = "us-east-1"
}

module "vpc" {
  source = "../../modules/vpc"

  name            = "shared"
  vpc_cidr        = "10.0.0.0/16"

  public_subnets = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  private_subnets = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
  }
}