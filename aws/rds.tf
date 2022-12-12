resource "random_password" "rds_password" {
  length = 16
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.0"

  count = var.db_type == "rds-postgresql" ? 1 : 0

  identifier = "skywalking-test"

  allocated_storage     = 5
  max_allocated_storage = 100

  db_name                = var.db_name
  username               = var.db_username
  password               = try(var.db_password, random_password.rds_password.result)
  create_random_password = false
  port                   = "5432"

  create_db_subnet_group              = true
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true

  vpc_security_group_ids = [module.vpc.default_security_group_id, aws_security_group.allow_apps.id]

  multi_az = "false"

  maintenance_window      = "Wed:00:00-Wed:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = "35"

  monitoring_role_name   = "RDSMonitoringRole"
  create_monitoring_role = false

  subnet_ids = module.vpc.private_subnets

  engine                 = "postgres"
  engine_version         = "14.1"
  family                 = "postgres14"
  major_engine_version   = "14"
  instance_class         = "db.m6g.2xlarge"
  create_db_option_group = "false"

  parameters = [
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 7.0"

  count = var.db_type == "aurora-postgresql" ? 1 : 0

  name           = "skywalking-test-aurora"
  engine         = "aurora-postgresql"
  engine_version = "14.3"
  instance_class = "db.r6g.2xlarge"
  instances = {
    one = {}
    two = {}
  }
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = try(var.db_password, random_password.rds_password.result)
  create_random_password = false
  skip_final_snapshot    = true
  apply_immediately      = true
  create_monitoring_role = true
  create_db_subnet_group = true

  vpc_id                  = module.vpc.vpc_id
  subnets                 = module.vpc.private_subnets
  allowed_security_groups = [module.vpc.default_security_group_id, aws_security_group.allow_apps.id]
  vpc_security_group_ids  = [module.vpc.default_security_group_id, aws_security_group.allow_apps.id]
}

resource "aws_security_group" "allow_apps" {
  name        = "allow_apps"
  description = "Allow apps inbound traffic and database outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_primary_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
