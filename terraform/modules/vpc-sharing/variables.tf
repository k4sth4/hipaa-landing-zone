variable "dev_account_id" {
  type        = string
  description = "Dev AWS Account ID"
}

variable "prod_account_id" {
  type        = string
  description = "Prod AWS Account ID"
}

variable "private_subnet_arns" {
  type        = list(string)
  description = "List of private subnet ARNs to share"
}