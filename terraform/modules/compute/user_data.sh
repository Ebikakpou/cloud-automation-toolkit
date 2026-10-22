#!/bin/bash
set -euxo pipefail

exec > >(tee /var/log/cloudshift-user-data.log | logger -t cloudshift-user-data) 2>&1

echo "Starting CloudShift Store Kubernetes provisioning..."
echo "Environment: ${environment}"

dnf update -y
dnf install -y docker git curl

systemctl enable --now docker

until docker info >/dev/null 2>&1; do
  echo "Waiting for Docker..."
  sleep 3
done

usermod -aG docker ec2-user

# Install a lightweight, full Kubernetes distribution.
# Traefik is disabled because the application uses host port 80.
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --disable=traefik" sh -

systemctl enable --now k3s

until k3s kubectl get nodes 2>/dev/null | grep -q ' Ready '; do
  echo "Waiting for Kubernetes node to become Ready..."
  sleep 5
done

rm -rf /home/ec2-user/app

git clone \
  -b main \
  --single-branch \
  https://github.com/Ebikakpou/cloud-automation-toolkit.git \
  /home/ec2-user/app

cd /home/ec2-user/app

test -f Dockerfile
test -f kubernetes/cloudshift-stack.yaml

# Build the application image using Docker.
docker build -t cloudshift-store:latest .

# Import the image into K3s/containerd.
docker save cloudshift-store:latest -o /tmp/cloudshift-store.tar
k3s ctr images import /tmp/cloudshift-store.tar
rm -f /tmp/cloudshift-store.tar

# Deploy the website and monitoring stack.
k3s kubectl apply -f kubernetes/cloudshift-stack.yaml

# Wait for the workloads to become ready.
k3s kubectl rollout status deployment/cloudshift-store --timeout=300s
k3s kubectl rollout status deployment/prometheus --timeout=300s
k3s kubectl rollout status deployment/grafana --timeout=300s
k3s kubectl rollout status deployment/node-exporter --timeout=300s

echo "===== KUBERNETES NODES ====="
k3s kubectl get nodes -o wide

echo "===== KUBERNETES PODS ====="
k3s kubectl get pods -o wide

echo "===== KUBERNETES SERVICES ====="
k3s kubectl get services

echo "CloudShift Store Kubernetes provisioning completed."
