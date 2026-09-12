#!/bin/bash

set -euxo pipefail

# Log everything for troubleshooting
exec > >(tee /var/log/cloudshift-user-data.log | logger -t cloudshift-user-data) 2>&1

echo "Starting CloudShift Store provisioning..."

# -----------------------------------------
# 1. Update packages
# -----------------------------------------
dnf update -y

# -----------------------------------------
# 2. Install Docker and Git
# -----------------------------------------
dnf install -y docker git

# -----------------------------------------
# 3. Start Docker
# -----------------------------------------
systemctl enable docker
systemctl start docker

# Wait until Docker is ready
until systemctl is-active --quiet docker; do
    echo "Waiting for Docker to start..."
    sleep 2
done

echo "Docker is running."

# -----------------------------------------
# 4. Allow ec2-user to use Docker
# -----------------------------------------
usermod -aG docker ec2-user

# -----------------------------------------
# 5. Clone the monitoring branch
# -----------------------------------------
rm -rf /home/ec2-user/app

git clone \
  -b monitoring-logging \
  --single-branch \
  https://github.com/Ebikakpou/cloud-automation-toolkit.git \
  /home/ec2-user/app

# -----------------------------------------
# 6. Move into application directory
# -----------------------------------------
cd /home/ec2-user/app

# -----------------------------------------
# 7. Verify Docker Compose
# -----------------------------------------
docker compose version

# -----------------------------------------
# 8. Start CloudShift Store
#    Prometheus
#    Grafana
# -----------------------------------------
docker compose up -d --build

# Show running containers

docker compose ps

echo "-----------------------------------------"
echo "CloudShift Store provisioning completed!"
echo "CloudShift Store: http://EC2_PUBLIC_IP"
echo "Prometheus:       http://EC2_PUBLIC_IP:9090"
echo "Grafana:          http://EC2_PUBLIC_IP:3000"
echo "-----------------------------------------"