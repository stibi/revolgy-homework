module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.17.0"

  identifier = "revolgy-homework"

  engine               = "postgres"
  engine_version       = "9.6.9"
  instance_class       = "db.t2.large"
  allocated_storage    = 5
  storage_encrypted    = false
  family               = "postgres9.6"
  major_engine_version = "9.6"
  deletion_protection  = false
  publicly_accessible  = true

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  username = var.rds_user
  password = var.rds_password
  port     = "5432"

  subnet_ids             = module.vpc.public_subnets
  vpc_security_group_ids = [module.vpc.default_security_group_id, "sg-0f6758a31b4e7aa13"]

  tags = {
    Project     = "revolgy-homework"
    Terraform   = "true"
    Environment = "homework"
  }
}

