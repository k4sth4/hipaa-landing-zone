variable "analyzer_name" {
  type = string
}

variable "analyzer_type" {
  type    = string
  default = "ACCOUNT" 
}

variable "tags" {
  type = map(string)
}