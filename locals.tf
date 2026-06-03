locals {
  name = "${var.environment}-${var.project_name}-eks"

  common_tags = {
    Name               = local.name
    Application        = var.application
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    Environment        = var.environment
    ManagedBy          = "terraform"
    Owner              = var.owner
  }

  private_subnet_ids                    = values(module.vpc.private_subnet_ids)
  private_route_table_ids               = values(module.vpc.private_route_table_ids)
  private_network_cidr                  = var.ipam_pool_cidr
  cluster_public_cidrs                  = var.endpoint_public_access ? var.endpoint_public_access_cidrs : []
  platform_admin_trusted_principal_arns = length(var.platform_admin_trusted_principal_arns) > 0 ? var.platform_admin_trusted_principal_arns : [data.aws_caller_identity.current.arn]
}
