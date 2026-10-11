variable "aws_region" {
  type    = string
  description = "AWS region for the state bucket"
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state"
}