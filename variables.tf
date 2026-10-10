variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "ubuntu-docker"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name in AWS"
}

variable "private_key_path" {
  type        = string
  description = ""
}

variable "ssh_cidr" {
  type        = string
  description = "10.0.0.0/24"
}

variable "allow_http" {
  type    = bool
  default = false
}

variable "instance_count" {
  type    = number
  default = 1
}