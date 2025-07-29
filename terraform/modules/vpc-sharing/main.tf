resource "aws_ram_resource_share" "vpc_share" {
  name                      = "Shared-VPC-Subnets"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "dev" {
  principal          = var.dev_account_id
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

resource "aws_ram_principal_association" "prod" {
  principal          = var.prod_account_id
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

resource "aws_ram_resource_association" "private_subnets" {
  for_each           = toset(var.private_subnet_arns)
  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}