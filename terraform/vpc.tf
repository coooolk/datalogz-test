data "aws_availability_zones" "azs" {
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "datalogz-test-vpc"
  cidr = var.vpc_cidr

  azs = data.aws_availability_zones.azs.names

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
}