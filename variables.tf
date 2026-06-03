variable "aws_region" {
  description = "AWS region for this live environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project or platform short name."
  type        = string
  default     = "midh"
}

variable "application" {
  description = "Application tag value."
  type        = string
  default     = "platform-eks"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = "shared-services"
}

variable "data_classification" {
  description = "Data classification tag value."
  type        = string
  default     = "internal"
}

variable "ipam_scope_id" {
  description = "Existing AWS IPAM private scope ID used to create the regional EKS VPC pool."
  type        = string
  default     = "ipam-scope-0711e0ade1f4814ae"
}

variable "ipam_pool_cidr" {
  description = "Regional CIDR provisioned into the EKS IPAM pool."
  type        = string
  default     = "10.60.0.0/16"
}

variable "vpc_ipv4_netmask_length" {
  description = "VPC netmask length allocated from IPAM."
  type        = number
  default     = 20
}

variable "permissions_boundary_arn" {
  description = "Enterprise IAM permissions boundary ARN for EKS roles."
  type        = string
}

variable "platform_admin_trusted_principal_arns" {
  description = "IAM principal ARNs allowed to assume the platform EKS admin role. Defaults to the Terraform caller when empty."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Approved Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.34"
}

variable "endpoint_private_access" {
  description = "Enable private EKS API endpoint access."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public EKS API endpoint access for current local lab bootstrap."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Public CIDRs allowed to reach the EKS API endpoint. Current lab uses the home/runner/AWX public IP."
  type        = list(string)
  default     = ["73.115.41.87/32"]
}

variable "node_instance_types" {
  description = "Instance types for the default EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_scaling_config" {
  description = "Default EKS managed node group scaling configuration."
  type = object({
    desired_size = number
    min_size     = number
    max_size     = number
  })
  default = {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }
}

variable "cloudwatch_retention_days" {
  description = "EKS control-plane log retention."
  type        = number
  default     = 365
}
