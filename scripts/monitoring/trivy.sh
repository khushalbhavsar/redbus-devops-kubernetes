#!/bin/bash
# Script to install Trivy on Amazon Linux

# Update system packages
sudo yum update -y

# Install necessary dependencies
sudo yum install -y wget

# Create Trivy repository file
cat <<EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=0
enabled=1
EOF

# Install Trivy
sudo yum install trivy -y

# Verify installation
trivy --version