terraform {
  backend "s3" {
    bucket       = "dami-terraform-state-2026"
    key          = "docker-host/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}