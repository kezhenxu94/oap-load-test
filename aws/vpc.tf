module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "skywalking-test-vpc"
  cidr = var.cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
