
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_security_group" "cloudshift_store" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow HTTP to the app and SSH for management"

  ingress {
    description = "HTTP - the app itself"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH - management access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
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

    resource "aws_instance" "cloudshift_store" {
        ami           = data.aws_ami.amazon_linux.id
        instance_type = var.instance_type
        key_name      = var.key_name
        vpc_security_group_ids = [aws_security_group.cloudshift_store.id]

        user_data = templatefile("${path.module}/user_data.sh", {
            environment  = var.environment
        })

        tags = {
            Name        = "${var.project_name}-${var.environment}"
            ManagedBy   = "Terraform"
            Environment = var.environment
            project     = var.project_name
        }

}

