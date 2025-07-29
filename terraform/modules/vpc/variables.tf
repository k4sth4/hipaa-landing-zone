variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of AZs to CIDR blocks for public subnets"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of AZs to CIDR blocks for private subnets"
  type        = map(string)
}