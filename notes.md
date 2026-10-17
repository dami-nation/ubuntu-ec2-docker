Bootstrap directory was created to store our s3 backend information, and the other infra- ec2, docker etc were moved to the infrastructure directory

I will migrate teh state from my local machine to the remote that is being hosted on an s3 bucket with terraform init -migrate-state

# Terraform Project Log

## Session 1 — Baseline Deployment

### Goal

Confirm the existing Docker host can still be deployed successfully.

### Work completed

- Ran `terraform fmt`
- Initialized the working directory
- Validated the configuration
- Created the EC2 instance
- Verified Docker installation

### Commands used

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply