module "vpc_sharing" {
  source = "../../modules/vpc-sharing"

  dev_account_id       = "088044431771"
  prod_account_id      = "674845782471"
  private_subnet_arns  = [
    "arn:aws:ec2:us-east-1:749717458225:subnet/subnet-0a114eaf6b3ed7dc8",
    "arn:aws:ec2:us-east-1:749717458225:subnet/subnet-0e28ff99ce75fbd7a"
  ]
}