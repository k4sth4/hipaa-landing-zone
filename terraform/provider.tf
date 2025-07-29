provider "aws" {
  alias  = "management"
  region = "us-east-1"
  profile = "mgmt"
}

provider "aws" {
  alias  = "security"
  region = "us-east-1"
  profile = "security"
}

provider "aws" {
  alias  = "dev"
  region = "us-east-1"
  profile = "dev"
}

provider "aws" {
  alias  = "prod"
  region = "us-east-1"
  profile = "prod"
}

provider "aws" {
  alias  = "shared"
  region = "us-east-1"
  profile = "shared"
}