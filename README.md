# Terraform Ubuntu Docker Host

This repository provisions a disposable Ubuntu EC2 instance with Docker installed automatically.

I use it when I need a clean Linux environment for testing Docker images or validating changes without repeatedly configuring a server through the AWS console.

The original version of this project is documented here:

https://oladami.com/posts/terraform-ubuntu/

The project has since been extended with remote Terraform state, state locking, lifecycle controls and GitHub Actions validation.

## What This Project Creates

The main infrastructure configuration creates:

- An Ubuntu 22.04 EC2 instance
- A security group with SSH access restricted to a specified CIDR
- Optional HTTP access
- Docker installed through `user_data`
- A public IP and generated SSH command
- One or more instances using `instance_count`

The supporting bootstrap configuration creates:

- An S3 bucket for Terraform state
- S3 bucket versioning
- Server-side encryption
- Public-access blocking
- Destruction protection with `prevent_destroy`

## Repository Structure

```text
ubuntu-ec2-docker/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml
├── bootstrap/
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── infrastructure/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── user_data.sh
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
└── README.md
```

The two Terraform directories have separate responsibilities:

- `bootstrap/` creates the long-lived S3 state bucket.
- `infrastructure/` creates the disposable EC2 instance and security group.

Terraform operates on the `.tf` files in the current directory. Commands must therefore be run from the appropriate directory.

## Prerequisites

Before using the project, you need:

- An AWS account
- AWS CLI credentials configured locally
- Terraform 1.10 or newer
- An existing EC2 key pair
- Your public IP address in CIDR notation, such as `203.0.113.10/32`

Confirm that AWS authentication works:

```bash
aws sts get-caller-identity
```

## 1. Create the Remote-State Bucket

The S3 bucket must exist before the main infrastructure can use it as a backend.

Move into the bootstrap directory:

```bash
cd bootstrap
terraform init
```

Preview the state-bucket configuration:

```bash
terraform plan \
  -var="state_bucket_name=YOUR-GLOBALLY-UNIQUE-BUCKET-NAME"
```

Create the bucket:

```bash
terraform apply \
  -var="state_bucket_name=YOUR-GLOBALLY-UNIQUE-BUCKET-NAME"
```

Use a globally unique S3 bucket name.

The bootstrap configuration enables versioning, encryption and public-access blocking. It also uses `prevent_destroy` as protection against accidentally deleting the state bucket through Terraform.

After creating the bucket, update the bucket name in:

```text
infrastructure/backend.tf
```

The name in `backend.tf` must match the bucket created by `bootstrap/`.

## 2. Configure the EC2 Infrastructure

Move into the infrastructure directory:

```bash
cd ../infrastructure
```

Create your local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your values:

```hcl
aws_region       = "us-east-1"
name_prefix      = "ubuntu-docker"
instance_type    = "t2.micro"
key_name         = "YOUR-EC2-KEY-PAIR-NAME"
private_key_path = "/path/to/your/private-key.pem"
ssh_cidr         = "YOUR-PUBLIC-IP/32"
allow_http       = false
instance_count   = 1
```

Do not commit `terraform.tfvars`. It is excluded through `.gitignore`.

## 3. Initialize the S3 Backend

Initialize the infrastructure configuration:

```bash
terraform init
```

If migrating existing local state into S3, use:

```bash
terraform init -migrate-state
```

The infrastructure state is stored at the S3 key configured in `backend.tf`:

```text
docker-host/terraform.tfstate
```

The backend also uses an S3 lock file to prevent concurrent Terraform operations from modifying the same state simultaneously.

## 4. Plan and Apply

Format and validate the configuration:

```bash
terraform fmt -recursive
terraform validate
```

Review the proposed changes:

```bash
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

After the apply completes, Terraform returns the public IP and an SSH command.

Example:

```bash
ssh -i /path/to/private-key.pem ubuntu@PUBLIC-IP
```

## 5. Verify Docker

Connect to the EC2 instance and verify Docker:

```bash
docker --version
sudo systemctl status docker
```

The `user_data.sh` script installs and starts Docker during the EC2 instance's initial boot.

## Remote State

The Terraform code is stored in Git, while the infrastructure state is stored separately in S3.

The state file connects Terraform resource addresses, such as:

```text
aws_instance.ubuntu[0]
```

to the real AWS resource IDs that Terraform manages.

The S3 backend provides:

- Remote state storage
- State versioning through the S3 bucket
- Encryption at rest
- State locking
- Separation between source code and operational state

Terraform state should not be committed to Git because it can contain sensitive or operationally important information.

## Drift Detection

If a managed EC2 instance is manually deleted through the AWS console, the Terraform configuration still declares that the instance should exist.

The next:

```bash
terraform plan
```

refreshes Terraform's view of AWS, detects the missing instance and proposes creating a replacement.

Terraform does not continuously reconcile infrastructure like Kubernetes. Drift is detected when Terraform runs manually or through automation.

## Lifecycle Replacement

The EC2 resource uses:

```hcl
lifecycle {
  create_before_destroy = true
}
```

When Terraform must replace the instance, this instructs it to create the replacement before destroying the existing instance when possible.

This changes replacement order but does not provide full high availability or guarantee zero downtime.

## GitHub Actions

Pull requests targeting `main` run the Terraform CI workflow located at:

```text
.github/workflows/terraform-ci.yml
```

The workflow runs:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate -no-color
```

These checks verify formatting and configuration validity without accessing the real S3 backend or deploying anything to AWS.

The workflow does not currently run `terraform plan` or `terraform apply`, so AWS credentials are not required.

## Destroying the Disposable Infrastructure

When finished, destroy the EC2 infrastructure from the `infrastructure/` directory:

```bash
terraform destroy
```

This removes the EC2 instance and its Terraform-managed security group. It also updates the remote state to record that the resources no longer exist.

Do not routinely destroy the bootstrap configuration. The S3 bucket is intended to remain available for future Terraform operations.

Destroying the EC2 infrastructure does not remove your code or project progress. The configuration remains in Git, and the Terraform state foundation remains in S3.

## Security Notes

- Restrict `ssh_cidr` to your current public IP using `/32`.
- Do not commit `terraform.tfvars`, private keys or state files.
- Never place AWS access keys directly in Terraform files.
- Review every Terraform plan before applying it.
- The state bucket is configured to block public access.
- `prevent_destroy` is a Terraform guardrail, not absolute protection against manual AWS deletion.

## Project Status

This project currently demonstrates:

- Terraform-managed EC2 infrastructure
- Docker installation through `user_data`
- Variables, outputs, data sources and `count`
- S3 remote state
- S3 state locking
- State-bucket versioning and encryption
- Drift detection and reconciliation
- Lifecycle replacement behavior
- Git feature-branch workflow
- Pull-request formatting and validation checks

A future iteration may add AWS authentication through GitHub Actions using OpenID Connect rather than long-lived AWS access keys.