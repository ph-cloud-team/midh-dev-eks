module "ipam_pool" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-ipam-pool.git?ref=v1.0.0"

  description   = "Regional private IPAM pool for ${local.name}"
  ipam_scope_id = var.ipam_scope_id
  locale        = var.aws_region
  pool_cidr     = var.ipam_pool_cidr

  allocation_default_netmask_length = var.vpc_ipv4_netmask_length
  allocation_min_netmask_length     = 20
  allocation_max_netmask_length     = 24

  allocation_resource_tags = {
    Environment = var.environment
    Owner       = var.owner
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-ipam-pool"
  })
}

module "vpc" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-vpc.git?ref=v1.0.0"

  name                 = local.name
  ipv4_ipam_pool_id    = module.ipam_pool.ipam_pool_id
  ipv4_netmask_length  = var.vpc_ipv4_netmask_length
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  flow_log_kms_key_arn              = module.cluster_kms.key_arn
  flow_log_permissions_boundary_arn = var.permissions_boundary_arn

  tags = local.common_tags
}

module "cluster_security_group" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-security-groups.git?ref=v1.0.0"

  name        = "${local.name}-cluster-sg"
  description = "Additional EKS cluster security group for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  egress_rules = {
    https_vpc = {
      description = "Allow HTTPS egress to private VPC services"
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = local.private_network_cidr
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-cluster-sg"
  })
}

module "cluster_kms" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-kms-key.git?ref=v1.0.0"

  alias_name  = "${local.name}-cluster"
  description = "KMS key for ${local.name} EKS secret encryption and control-plane logs"

  service_principals = [
    "eks.amazonaws.com",
    "logs.${var.aws_region}.amazonaws.com"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-cluster-kms"
  })
}

module "node_kms" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-kms-key.git?ref=v1.0.0"

  alias_name  = "${local.name}-nodes"
  description = "KMS key for ${local.name} EKS worker node volumes"

  service_principals = [
    "ec2.${var.aws_region}.amazonaws.com",
    "autoscaling.amazonaws.com"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-node-kms"
  })
}

module "ecr_kms" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-kms-key.git?ref=v1.0.0"

  alias_name  = "${local.name}-ecr"
  description = "KMS key for ${local.name} ECR repositories"

  service_principals = [
    "ecr.amazonaws.com"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-ecr-kms"
  })
}

module "cluster_log_group" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/observability/tf-aws-cloudwatch-log-group.git?ref=v1.0.0"

  name              = "/aws/eks/${local.name}/cluster"
  kms_key_id        = module.cluster_kms.key_arn
  retention_in_days = var.cloudwatch_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name}-control-plane-logs"
  })
}

module "cluster_role" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-iam-role.git?ref=v1.0.0"

  name                       = "${local.name}-cluster-role"
  description                = "EKS cluster service role for ${local.name}"
  permissions_boundary       = var.permissions_boundary_arn
  trusted_service_principals = ["eks.amazonaws.com"]

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-cluster-role"
  })
}

module "node_role" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-iam-role.git?ref=v1.0.0"

  name                       = "${local.name}-node-role"
  description                = "EKS managed node group role for ${local.name}"
  permissions_boundary       = var.permissions_boundary_arn
  trusted_service_principals = ["ec2.amazonaws.com"]

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-node-role"
  })
}

module "platform_admin_role" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/security/tf-aws-iam-role.git?ref=v1.0.0"

  name                       = "${local.name}-platform-admin-role"
  description                = "Platform EKS administration role for ${local.name}"
  permissions_boundary       = var.permissions_boundary_arn
  trusted_aws_principals     = local.platform_admin_trusted_principal_arns
  max_session_duration       = 14400
  force_detach_policies      = true
  require_trust_policy       = true
  trusted_service_principals = []

  tags = merge(local.common_tags, {
    Name = "${local.name}-platform-admin-role"
  })
}

module "vpc_endpoints" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-vpc-endpoints.git?ref=v1.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints                                = {}
  enable_eks_private_endpoint_set          = true
  private_subnet_ids                       = local.private_subnet_ids
  private_route_table_ids                  = local.private_route_table_ids
  create_interface_endpoint_security_group = true
  interface_endpoint_ingress_cidr_blocks   = [local.private_network_cidr]

  tags = merge(local.common_tags, {
    Name = "${local.name}-endpoints"
  })
}

module "eks_cluster" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/containers/tf-aws-eks-cluster.git?ref=v1.0.0"

  name               = local.name
  cluster_role_arn   = module.cluster_role.role_arn
  kubernetes_version = var.kubernetes_version
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [module.cluster_security_group.security_group_id]

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = local.cluster_public_cidrs

  secrets_kms_key_arn = module.cluster_kms.key_arn

  access_entries = {
    platform_admin = {
      principal_arn = module.platform_admin_role.role_arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.common_tags

  depends_on = [
    module.cluster_log_group,
    module.vpc_endpoints
  ]
}

module "system_node_group" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/containers/tf-aws-eks-node-group.git?ref=v1.0.0"

  name               = "${local.name}-system"
  cluster_name       = module.eks_cluster.cluster_name
  node_role_arn      = module.node_role.role_arn
  subnet_ids         = local.private_subnet_ids
  kms_key_arn        = module.node_kms.key_arn
  kubernetes_version = var.kubernetes_version
  instance_types     = var.node_instance_types
  scaling_config     = var.node_scaling_config

  labels = {
    nodepool = "system"
  }

  tags = local.common_tags
}

module "platform_tools_ecr" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/containers/tf-aws-ecr-repository.git?ref=v1.0.0"

  name        = "${local.name}/platform-tools"
  kms_key_arn = module.ecr_kms.key_arn

  read_principal_arns = [
    module.node_role.role_arn
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-platform-tools-ecr"
  })
}

module "ebs_csi_irsa" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/containers/tf-aws-eks-irsa.git?ref=v1.0.0"

  name                 = "${local.name}-ebs-csi-role"
  description          = "IRSA role for the EBS CSI controller in ${local.name}"
  permissions_boundary = var.permissions_boundary_arn
  oidc_provider_arn    = module.eks_cluster.oidc_provider_arn
  oidc_provider_url    = module.eks_cluster.oidc_provider_url

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"
    }
  ]

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-ebs-csi-role"
  })
}

module "eks_addons" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/containers/tf-aws-eks-addons.git?ref=v1.0.0"

  cluster_name       = module.eks_cluster.cluster_name
  kubernetes_version = var.kubernetes_version

  addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.role_arn
    }
  }

  tags = local.common_tags

  depends_on = [
    module.system_node_group,
    module.ebs_csi_irsa
  ]
}
