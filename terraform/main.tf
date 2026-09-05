# main.tf — the actual infrastructure. Two resources: a security group
# (the firewall rule for this instance) and the EC2 instance itself.
# Compare the length of this file to how many clicks the AWS console
# takes to do the same thing by hand — and console clicks leave no
# record anywhere of what was clicked, in what order, or why.
# Always ask for the CURRENT latest Amazon Linux AMI instead of hardcoding
# an AMI ID. AMI IDs are region-specific and go stale — a hardcoded one 
# from today silently breaks (or worse, silently uses an old image) the 
# moment you change region or come back to this in six months.

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
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.cloudshift_store.id]

  # Automatically run the EC2 bootstrap script when the instance is created.
  # The script will install Docker and start the application.
  user_data = templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  })

  # Recreate the EC2 instance when user_data.sh changes.
  user_data_replace_on_change = true

  # Every resource is tagged the same way, every time — no more "which
  # instance was this again?" guessing games in the AWS console.
  tags = {
    Name        = "${var.project_name}-${var.environment}"
    ManagedBy   = "Terraform"
    Environment = var.environment
    Project     = var.project_name
  }
}