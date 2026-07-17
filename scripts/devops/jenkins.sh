#!/bin/bash
#this Script belong to Cloudaseem Youtube channel #####
# Jenkins installation on Amazon Linux

# Update system packages
sudo yum update -y

# Install Java 17 (Amazon Corretto)
sudo yum install java-17-amazon-corretto-devel -y

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import Jenkins GPG key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo yum install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Display initial admin password location
echo "Jenkins initial admin password can be found at: /var/lib/jenkins/secrets/initialAdminPassword"