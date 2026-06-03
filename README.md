# midh-dev-eks

Live Terraform stack for the dev EKS platform foundation.

This repository composes the approved local Terraform modules into a private-first EKS environment. It is intentionally built in dependency order so each layer can pass governance, Checkov, and OPA policy checks through the shared GitLab pipeline.

## What This Stack Builds

- Regional IPAM pool for EKS VPC allocations.
- EKS VPC with public/private subnets and one NAT gateway for the current dev lab.
- Private AWS service endpoints for EKS workloads.
- KMS keys for cluster secrets, control-plane logs, and worker node volumes.
- IAM roles for the EKS cluster and managed node group.
- IAM role for platform EKS administration.
- IRSA role for the EBS CSI controller.
- ECR repository for platform tools and future cluster automation images.
- EKS cluster with private endpoint enabled.
- Temporary lab public endpoint access restricted to `73.115.41.87/32`.
- Managed node group in private subnets.
- Baseline EKS managed add-ons.

## Lab Networking Decision

The current local GitLab runner and AWX controller are outside the EKS VPC and use the local lab network. For bootstrap, this stack sets:

```hcl
endpoint_private_access = true
endpoint_public_access  = true
endpoint_public_access_cidrs = ["73.115.41.87/32"]
```

This is not the final production posture. The public endpoint remains restricted to a single `/32` while local HTTP GitLab and AWX are used. When runner/AWX have private network reachability to the EKS endpoint, public endpoint access should be disabled.

## Module Dependency Order

1. `tf-aws-ipam-pool`
2. `tf-aws-vpc`
3. `tf-aws-security-groups`
4. `tf-aws-kms-key`
5. `tf-aws-cloudwatch-log-group`
6. `tf-aws-iam-role`
7. `tf-aws-vpc-endpoints`
8. `tf-aws-ecr-repository`
9. `tf-aws-eks-cluster`
10. `tf-aws-eks-node-group`
11. `tf-aws-eks-irsa`
12. `tf-aws-eks-addons`

## Pipeline

This repo includes the centralized live Terraform pipeline:

```yaml
include:
  - project: infra_team/platform-pipelines
    ref: main
    file: terraform/live/aws.yml
```

The shared pipeline is expected to run formatting, validation, Checkov, TFLint, Terraform plan, OPA plan checks, and controlled apply/destroy jobs.

## Required CI Variables

- `AWS_DEFAULT_REGION`
- AWS credentials or role-assumption variables expected by the shared runner image
- `TF_VAR_permissions_boundary_arn`

Optional:

- `TF_VAR_platform_admin_trusted_principal_arns`

When `TF_VAR_platform_admin_trusted_principal_arns` is not set, the platform admin role trusts the IAM principal running Terraform. In the current lab, that is the GitLab runner AWS caller. For a more formal setup, set it to the IAM role or IAM user ARNs that should be allowed to assume the EKS platform admin role.

## Module Sources

This live stack consumes module repositories through local GitLab HTTP module sources, matching the established `midh-dev-ec2` pattern:

```hcl
source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-vpc.git?ref=v1.0.0"
```

Each module must be tagged and available to the GitLab runner before this live stack can run through the shared pipeline.

## Local Validation

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```
