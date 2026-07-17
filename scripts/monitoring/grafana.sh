#!/bin/bash
# Script to install Grafana on Amazon Linux

# Update system packages
sudo yum update -y

# Install required dependencies
sudo yum install -y wget

# Create Grafana repository file
cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install Grafana
sudo yum install grafana -y

# Reload systemd daemon
sudo systemctl daemon-reload

# Start and enable Grafana service
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# After installation, you can access Grafana at:
# http://your-server-ip:3000 (default user: admin, password: admin)