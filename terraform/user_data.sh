set -euxo pipefail

dnf update -y
dnf install -y docker git

systemctl start docker
systemctl enable docker

usermod -aG docker ec2-user

git clone https://github.com/Ebikakpou/cloud-automation-toolkit.git /home/ec2-user/app
cd /home/ec2-user/app

docker build -t cloudshift-store:v1 .

docker run -d \
  --name cloudshift-store \
  --restart unless-stopped \
  -p 80:5000 \
  -e PROVISIONED_BY=terraform \
  -e ENVIRONMENT=${environment} \
  -e APP_VERSION=v1.3.0 \
  -e ACCENT_COLOR="#e8772d" \
  cloudshift-store:v1