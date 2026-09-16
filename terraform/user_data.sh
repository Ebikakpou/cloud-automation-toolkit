#!/bin/bash

set -euxo pipefail

# Log everything for troubleshooting
exec > >(tee /var/log/cloudshift-user-data.log | logger -t cloudshift-user-data) 2>&1

echo "Starting CloudShift Store provisioning..."

# Update packages
dnf update -y

# Install Docker and Git automatically
dnf install -y docker git

# Start Docker automatically
systemctl enable docker
systemctl start docker

# Allow ec2-user to use Docker
usermod -aG docker ec2-user

# Clone the application repository
git clone \
  https://github.com/Ebikakpou/cloud-automation-toolkit.git \
  /home/ec2-user/app

# Move into the application directory
cd /home/ec2-user/app

# Build the Docker image automatically
docker build -t cloudshift-store:v1.3.0 .

# Remove an old container if one exists
docker rm -f cloudshift-store || true

# Start the application automatically
docker run -d \
  --name cloudshift-store \
  --restart unless-stopped \
  -p 80:5000 \
  -e PROVISIONED_BY=terraform \
  -e ENVIRONMENT="${environment}" \
  -e APP_VERSION=v1.3.0 \
  -e ACCENT_COLOR="#e8772d" \
  cloudshift-store:v1.3.0

echo "CloudShift Store provisioning completed successfully!"