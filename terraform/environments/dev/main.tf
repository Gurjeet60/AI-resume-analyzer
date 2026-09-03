module "vpc" {
  source = "../../modules/vpc"

  name     = "ai-resume-analyzer-dev"
  vpc_cidr = "10.0.0.0/16"

  azs = [
    "ap-south-1a",
    "ap-south-1b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  database_subnet_cidrs = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}
module "ecr" {
  source = "../../modules/ecr"

  project_name = "ai-resume-analyzer"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "ai-resume-analyzer-dev"
  kubernetes_version = "1.33"

  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_type = "t4g.medium"
}

module "alb_controller" {
  source = "../../modules/alb-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url

  namespace            = "kube-system"
  service_account_name = "aws-load-balancer-controller"
}

module "rds" {
  source = "../../modules/rds"

  name        = "ai-resume-analyzer"
  environment = "dev"

  vpc_id = module.vpc.vpc_id

  database_subnet_ids = module.vpc.database_subnet_ids

  backend_security_group_id = module.eks.cluster_security_group_id

  database_name     = "resume_db"
  database_username = "resume_admin"

  engine_version = "16"

  # Cost-conscious development configuration
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 50

  backup_retention_period = 7

  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true
}