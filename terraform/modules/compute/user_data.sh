#!/bin/bash
set -Eeuo pipefail

exec > >(tee /var/log/cloudshift-user-data.log | logger -t cloudshift-user-data) 2>&1

trap 'echo "ERROR: provisioning failed at line ${LINENO}; check /var/log/cloudshift-user-data.log"' ERR

echo "Starting CloudShift Store provisioning..."
echo "Environment: ${environment}"

# Do not run a full system update during first-boot provisioning.
# Avoid installing curl because Amazon Linux may already provide curl-minimal.
dnf install -y docker git

if ! command -v curl >/dev/null 2>&1; then
  dnf install -y curl-minimal
fi

systemctl enable --now docker

until docker info >/dev/null 2>&1; do
  echo "Waiting for Docker..."
  sleep 3
done

usermod -aG docker ec2-user || true

# Install lightweight Kubernetes (K3s).
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --disable=traefik" sh -

systemctl enable --now k3s

for attempt in $(seq 1 60); do
  if k3s kubectl get nodes 2>/dev/null | grep -q ' Ready '; then
    break
  fi
  echo "Waiting for Kubernetes node..."
  sleep 5
done

k3s kubectl get nodes | grep -q ' Ready ' || {
  echo "Kubernetes node did not become Ready."
  exit 1
}

# Download the application and its Kubernetes configuration.
rm -rf /home/ec2-user/app

git clone \
  --depth 1 \
  --branch main \
  https://github.com/Ebikakpou/cloud-automation-toolkit.git \
  /home/ec2-user/app

cd /home/ec2-user/app

test -f Dockerfile
test -f kubernetes/cloudshift-stack.yaml

# Build with Docker and import the image into K3s containerd.
docker build -t cloudshift-store:latest .
docker save cloudshift-store:latest -o /tmp/cloudshift-store.tar
k3s ctr images import /tmp/cloudshift-store.tar
rm -f /tmp/cloudshift-store.tar

# Deploy the application and monitoring stack.
k3s kubectl apply -f kubernetes/cloudshift-stack.yaml

# Wait for all deployments.
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

echo "CloudShift Store provisioning completed successfully."
