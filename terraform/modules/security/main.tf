resource "aws_security_group" "cloudshift_store" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "CloudShift Store application access"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP application"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidr == "" ? [] : [var.allowed_ssh_cidr]

    content {
      description = "Restricted SSH management"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.monitoring_cidr == "" ? [] : [var.monitoring_cidr]

    content {
      description = "Restricted Prometheus access"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.monitoring_cidr == "" ? [] : [var.monitoring_cidr]

    content {
      description = "Restricted Grafana access"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sg"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}