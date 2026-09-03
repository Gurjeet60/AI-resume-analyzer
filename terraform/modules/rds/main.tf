# ---------------------------------------------------------
# Database Password
# ---------------------------------------------------------

resource "random_password" "database" {
  length  = 32

  special = true

  override_special = "!#$%&()*+-_=.?@"
}

# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name = "${var.name}-${var.environment}-rds-subnet-group"

  subnet_ids = var.database_subnet_ids

  tags = {
    Name        = "${var.name}-${var.environment}-rds-subnet-group"
    Environment = var.environment
    Project     = var.name
  }
}

# ---------------------------------------------------------
# RDS Security Group
# ---------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-${var.environment}-rds-sg"
  description = "Security group for ${var.name} PostgreSQL RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.name
  }
}

# ---------------------------------------------------------
# RDS PostgreSQL Instance
# ---------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = "${var.name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version

  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username
  password = random_password.database.result

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  multi_az = var.multi_az

  backup_retention_period = var.backup_retention_period

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  auto_minor_version_upgrade = true

  copy_tags_to_snapshot = true

  performance_insights_enabled = false

  apply_immediately = true

  tags = {
    Name        = "${var.name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.name
  }
}

# ---------------------------------------------------------
# Secrets Manager Secret
# ---------------------------------------------------------

resource "aws_secretsmanager_secret" "database" {
  name = "${var.name}/${var.environment}/database"

  description = "Database credentials for ${var.name} ${var.environment}"

  recovery_window_in_days = 0

  tags = {
    Name        = "${var.name}-${var.environment}-database-secret"
    Environment = var.environment
    Project     = var.name
  }
}

# ---------------------------------------------------------
# Database Secret Version
# ---------------------------------------------------------

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  secret_string = jsonencode({
    username = var.database_username
    password = random_password.database.result
    database = var.database_name
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    engine   = "postgres"
  })
}