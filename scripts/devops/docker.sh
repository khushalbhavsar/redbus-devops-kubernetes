#!/bin/bash
# Script to install Docker on Amazon Linux EC2 instance and configure permissions

# Update the package list
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Add the 'ec2-user' and 'jenkins' users to the 'docker' group to allow running Docker without sudo
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# Set correct permissions for the Docker socket to allow 'docker' group members to access it
sudo chmod 660 /var/run/docker.sock
sudo chown root:docker /var/run/docker.sock

# Restart Docker service to apply changes
sudo systemctl restart docker

# Apply the new group settings (Note: may require re-login for full effect)
newgrp docker

# Verify installation
docker --version

# Run SonarQube container in detached mode with port mapping
#docker run -d --name sonar -p 9000:9000 sonarqube:lts-community