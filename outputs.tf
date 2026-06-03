output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks_cluster.cluster_endpoint
}

output "vpc_id" {
  description = "EKS VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS."
  value       = local.private_subnet_ids
}

output "system_node_group_name" {
  description = "System managed node group name."
  value       = module.system_node_group.node_group_name
}

output "vpc_endpoint_ids" {
  description = "Private AWS service endpoint IDs."
  value       = module.vpc_endpoints.endpoint_ids
}

output "addon_versions" {
  description = "Installed EKS add-on versions."
  value       = module.eks_addons.addon_versions
}

output "cluster_security_group_id" {
  description = "Additional EKS cluster security group ID."
  value       = module.cluster_security_group.security_group_id
}

output "cluster_role_arn" {
  description = "EKS cluster IAM role ARN."
  value       = module.cluster_role.role_arn
}

output "node_role_arn" {
  description = "EKS node IAM role ARN."
  value       = module.node_role.role_arn
}

output "platform_admin_role_arn" {
  description = "IAM role ARN granted EKS platform administrator access."
  value       = module.platform_admin_role.role_arn
}

output "platform_tools_ecr_repository_url" {
  description = "Platform tools ECR repository URL."
  value       = module.platform_tools_ecr.repository_url
}

output "ebs_csi_irsa_role_arn" {
  description = "IRSA role ARN used by the EBS CSI controller add-on."
  value       = module.ebs_csi_irsa.role_arn
}
