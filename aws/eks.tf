module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name                  = var.cluster_name
  subnet_ids                    = module.vpc.private_subnets
  vpc_id                        = module.vpc.vpc_id

  eks_managed_node_groups = {
    prod = {
      instance_types = var.cluster_node_instance_types
      min_size       = var.cluster_node_size.min
      max_size       = var.cluster_node_size.max
      desired_size   = var.cluster_node_size.desired

      create_launch_template = false
      launch_template_name   = ""
    }
  }
}
