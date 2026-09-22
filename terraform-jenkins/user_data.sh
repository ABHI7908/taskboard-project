#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# --- Java (Jenkins requirement) ---
apt-get install -y fontconfig openjdk-17-jre unzip curl gnupg jq git

# --- Jenkins (official apt repo, LTS) ---
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  "https://pkg.jenkins.io/debian-stable binary/" | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins

# --- Docker (so Jenkins can build/push images) ---
curl -fsSL https://get.docker.com | sh
usermod -aG docker jenkins

# --- AWS CLI v2 ---
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# --- kubectl (pin to match the EKS cluster_version, currently 1.29) ---
curl -s -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# --- eksctl (handy for cluster debugging, optional but cheap to have) ---
curl -s --location \
  "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
  | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin/

# --- Trivy (vulnerability scanning stage) ---
curl -s https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

# --- Node.js 20 (to build/test the taskboard app) ---
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- sonar-scanner CLI ---
curl -s -Lo /tmp/sonar-scanner.zip \
  "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip"
unzip -q /tmp/sonar-scanner.zip -d /opt
ln -s /opt/sonar-scanner-*-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner

systemctl restart jenkins

echo "Bootstrap complete." > /tmp/bootstrap-done
