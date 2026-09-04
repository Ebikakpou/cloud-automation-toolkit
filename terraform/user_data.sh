```bash
#!/bin/bash

# user_data.sh — runs automatically, once, the first time this EC2
# instance boots.

set -euxo pipefail

# Update the system
dnf update -y

# Install required software
dnf install -y docker git

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Allow ec2-user to run Docker
usermod -aG docker ec2-user

# Clone the application repository
git clone \
  https://github.com/Ebikakpou/cloud-automation-toolkit.git \
  /home/ec2-user/app

# Move into the application directory
cd /home/ec2-user/app

# Build the Docker image
docker build -t cloudshift-store:v1 .

# Run the application container
docker run -d \
  --name cloudshift-store \
  --restart unless-stopped \
  -p 80:5000 \
  -e PROVISIONED_BY=terraform \
  -e ENVIRONMENT="${environment}" \
  -e APP_VERSION=v1.3.0 \
  -e ACCENT_COLOR="#e8772d" \
  cloudshift-store:v1
```
